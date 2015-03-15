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
	local function inner(req)
		local cookie = req.headers.cookie
		if cookie then
			local s = {}
			for k, v in cookie:gmatch('[^=]+') do
				table.insert(s, k)
			end
			req.session = s[2]
		else
			local id = genID()
			req.response:setHeader('Set-Cookie', 'session=' .. id)
			req.session = id
		end
	end
	return inner
end

return {
	serveWith = serveWith,
	wrapContentType = wrapContentType,
	wrapParams = wrapParams,
	wrapSession = wrapSession,
}
