# Static HTTP server in Bash and Netcat only

Don't ask me "why". Because I can.

Of course, there are better solutions to serve static, but Bash also can do it.

![screenshot](screenshot.png "screenshot")

## Dependencies

Expecting you have such binaries available:

* `bash` (tested on `GNU bash, versiya 5.1.16(1)-release (x86_64-pc-linux-gnu)`)
* `nc` (any netcat able to do `nc -l -k -p {PORT}`)
* `find` (tested on `find (GNU findutils) 4.9.0`)
* `stat` (tested on `stat (GNU coreutils) 9.1`)
* `file` (tested on `file-5.43`)
