# luvware
Performant, minimal middleware for [Luvit](https://github.com/luvit/luvit).

````
http = require('http')
lw = require('luvware')

function helloHandler(req)
	local name = req.params.name or 'nobody'
	req.response:finish('hello, ' .. name)
end

middleware = {
	lw.wrapContentType,
	lw.wrapParams,
	helloHandler
}

http.createServer(lw.serveWith(middleware)):listen(8080)
print('Server listening on port 8080!')
````