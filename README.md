# luvware
Performant, minimal middleware for Luvit.

To be used with [luvit](https://github.com/luvit/luvit)

````
http = require('http')
lw = require('luvware')

function handler(req)
	local name = req.params.name or 'nobody'
	req.response:finish('hello, ' .. name)
end

middleware = {
	lw.wrapContentType,
	lw.wrapParams,
	handler
}

http.createServer(lw.serveWith(middleware)):listen(8080)
print('Server listening on port 8080!')
````