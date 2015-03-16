require('math')

local function serveWith(ware)
	local function handler(req, res)
		req.response = res
		for k, v in pairs(ware) do
			v(req)
		end
	end
	return handler
end

local function wrapContentType(options)
	local function inner(req)
		req.response:setHeader('Content-Type', 'text/html')
	end
	return inner
end

local function wrapParams(options)
	local function inner(req)
		local sep = '&'
		local eq = '='
		local obj = {}
		local spliturl = {}
		local splitqs = {}
		local splitassign = {}

		req.params = {}

		for k, v in req.url:gmatch('[^?]+') do
			table.insert(spliturl, k)
		end

		req.url = spliturl[1]
		local qs = spliturl[2]

		if qs then
			for k, v in qs:gmatch('[^&]+') do
				table.insert(splitqs, k)
			end
			for i, q in pairs(splitqs) do
				splitassign = {}
				for k, v in q:gmatch('[^=]+') do
					table.insert(splitassign, k)
				end
				req.params[splitassign[1]] = splitassign[2]
			end
		end
	end
	return inner
end

local function wrapSession(options)
	local hex = '0123456789ABCDEF'
	local store = options.store or 'memory'
	local sessionStore
	local db

	local stmtQuerySession

	if store == 'memory' then
		sessionStore = {}
	else
		sqlite3 = require('ljsqlite3')
		db = sqlite3.open('sessions.db')
		db:exec[[
		create table if not exists sessions (
		id integer primary key,
		sessionid varchar,
		sessionkey varchar,
		sessionval varchar
		);
		]]
		stmtQuerySession = db:prepare[[
		select sessionval from sessions where sessionid = ? and sessionkey = ?;
		]]
	end

	local function int2hex(n)
		local s = ''
		local b = 16
		local d
		while n > 0 do
			d = n % b + 1
			n = math.floor(n / b)
			s = hex:sub(d, d) .. s
		end
		while #s < 2 do s = '0' .. s end
		return s
	end

	local function genID()
		return int2hex(math.random(0, 255)) ..
		int2hex(math.random(0, 255)) ..
		int2hex(math.random(0, 255)) ..
		int2hex(math.random(0, 255))
	end

	local function getSessionValue(id)
		local function inner(t, k)
			if store == 'memory' then
				return sessionStore[id][k]
			elseif store == 'sqlite' then
				stmtQuerySession:bind1(1, id)
				stmtQuerySession:bind1(2, k)
				resultset, nrow = stmtQuerySession:resultset()
				stmtQuerySession:reset()
				if nrow == 0 then
					return nil
				elseif nrow == 1 then
					-- first row, second value returned (sessionval)
					return resultset[1][1]
				else
					print('error! sqlite: sessionid '..id..' has '..nrow..' values for '..k)
					return nil
				end
			end
		end
		return inner
	end

	local function setSessionValue(id)
		local function inner(t, k, v)
			if store == 'memory' then
				sessionStore[id][k] = v
			elseif store == 'sqlite' then
				db:exec([[
				insert or replace into 
				sessions(id, sessionid, sessionkey, sessionval) 
				values(
				(select id from sessions where sessionid = ']]..id.."' and sessionkey = '"..k..[[')
				, ']]..id.."' ,'"..k.."' ,'"..v.."');")
			end
		end
		return inner
	end

	local function inner(req)
		local cookie = req.headers.cookie
		local id
		if cookie then
			local s = {}
			for k, v in cookie:gmatch('[^=]+') do
				table.insert(s, k)
			end
			id = s[2]
		else
			id = genID()
			req.response:setHeader('Set-Cookie', 'session=' .. id)
		end
		-- the browser can have a cookie but there isn't a store
		if store == 'memory' and not sessionStore[id] then sessionStore[id] = {} end
		req.session = setmetatable({}, {__index=getSessionValue(id), __newindex=setSessionValue(id)})
	end

	return inner
end

return {
	serveWith = serveWith,
	wrapContentType = wrapContentType,
	wrapParams = wrapParams,
	wrapSession = wrapSession,
}
