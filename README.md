# luvware

Performant, minimal middleware for [Luvit](https://github.com/luvit/luvit).

````lua
http = require('http')
lw = require('luvware')

function helloHandler(req)
	local name = req.params.name or 'nobody'
	req.response:finish('hello, ' .. name)
end

middleware = {
	lw.wrapContentType{},
	lw.wrapParams{},
	helloHandler
}

http.createServer(lw.serveWith(middleware)):listen(8080)
print('Server listening on port 8080!')
````

## Using luvware

luvware.serveWith takes a list of middleware functions and returns an HTTP handler function that accepts requests and calls the middleware in succession. Each middleware function can mutate the request table. The last function should handle the request and finish the response.

## Adding middleware

Each middleware function should accept a single request table, and does not have to return a value. 

Relevant keys in the request table:

**response**: this is the HTTP response table

**url**: the URL requested

**httpVersion**

Relevant keys in the response table:

**setHeader(key, val)**

**write(content)**: this writes content to the connection.

**finish(content)**: this sends content and closes the response. Nothing may be sent after this is called

````lua
function wrapURLPrinter(req)
	print('The URL requested is ' .. req.url)
end
````

## Included middleware

Some often-used middleware is included in this library for convenience.

### wrapParams

This will mutate (!) the req.url, removing URL-encoded parameters. A table named params containing parameters and their values as strings is added to the request table. An example of this is at the top of the page.

### wrapContentType

This is a work in progress, and currently just sets the Content-Type header to text/html. Soon, it will detect content type and set the header appropriately.

### wrapSession

This will add a table to the request map. It can be mutated, and will be preserved across a user's session. An ID is stored in the user's cookies, but all data is stored server-side.

The function to create wrapSession can be passed a 'store' key, which can either be 'memory' or 'sqlite'. Memory store is the default. This will keep the sessions in a table in memory. The 'sqlite' store will save the sessions to a database. To use the sqlite store, you will need to install the LJSqlite3 library found [here](http://scilua.org/get.html).
