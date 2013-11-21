class Chat

  constructor: (@socket, @fs = undefined) ->

  hello: (host, port) ->
    @socket.connect(port, host)
    
  goodbye: ->
    @socket.end()
    
  local_ip_address: ->
    @socket.address().address
    
  say: (message) ->
    @socket.write(message)
    
  say_with_logging: (message) ->
    @socket.write(message)
    @fs.appendFileSync("log.txt", message)



(exports ? window).Chat = Chat
