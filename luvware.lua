local function serveWith(ware)
	local function handler(req, res)
		req.response = res
		print("go request")
		for k, v in pairs(ware) do
			v(req)
		end
	end
	return handler
end

local function wrapContentType(req)
	req.response:setHeader('Content-Type', 'text/html')
end

local function wrapParams(req)
	local sep = '&'
	local eq = '='
	local obj = {}
	local spliturl = {}
	local splitqs = {}
	local splitassign = {}

	req.params = {}

	for k, v in req.url:gmatch('[^?]+') do
		print(k, v)
		table.insert(spliturl, k)
	end

	req.url = spliturl[1]
	local qs = spliturl[2]

	if qs then
		print('query string is ' .. qs)
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
	else
		print('no query string')
	end
end

return {
	serveWith = serveWith,
	wrapContentType = wrapContentType,
	wrapParams = wrapParams,
}
