describe "Chat.goodbye", ->
  it "ends the conversation", ->
    mock (socket) ->
      socket.expects("end")
      chat = new Chat(socket)
      chat.goodbye()

describe "Chat.hello", ->
  it "starts a conversation", ->
    mock (socket) ->
      socket.expects("connect").args(1234, "localhost")
      chat = new Chat(socket)
      chat.hello("localhost", 1234)
      
describe "Chat.local_ip_address", ->
  it "returns the ip address of the local end of the chat", ->
    mock (socket) ->
      socket.expects("address").returns( { port: 1234, family: "IPv4", address: "127.0.0.1" } )
      chat = new Chat(socket)
      chat.local_ip_address().should.equal "127.0.0.1"

describe "Chat.say", ->
  it "throws an error if the data to be sent is not a string", ->
    mock (socket) ->
      socket.expects("write").args(123).throws("invalid data")
      chat = new Chat(socket)
      (-> chat.say(123) ).should.throw("invalid data")

describe "Chat.say_with_logging", ->
  it "sends a message and also logs it to a file", ->
    mock (socket, fs) ->
      socket.expects("write").args("a message")
      fs.expects("appendFileSync").args("log.txt", "a message")
      chat = new Chat(socket, fs)
      chat.say_with_logging("a message")
