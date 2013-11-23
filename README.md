### TinyMockJS - A very small CoffeeScript mocking library



### Overview
TinyMockJS is a very small mocking library for use in CoffeeScript and JavaScript testing.  It was written as an exercise for learning CoffeeScript rather than as a complete mocking framework.
<br>



### Requirements
- [Node.js](http://nodejs.org)
- A testing framework, such as [mocha](http://visionmedia.github.io/mocha/) and [chai](http://chaijs.com).
<br>



### Installation
TODO
download TinyMockJS from github
cd path/to/TinyMockJS
npm link
cd path/to/MyProject
npm link TinyMockJS

To uninstall:
TODO
<br>



### Quick Start
- Use the mock function to create mock objects and run a test:
    ```CoffeeScript
    describe "Something", ->
      it "does something", ->
        mock (my_mocked_object) ->
          # test code goes here
    ```

- Use expects() to add a method that is expected to be called on a mocked object: 
    ```CoffeeScript
    describe "Chat.goodbye", ->
      it "ends the conversation", ->
        mock (socket) ->
          socket.expects("end")
          chat = new Chat(socket)
          chat.goodbye()
    ```

- Use args() to specify the arguments that a mocked method is expected to be called with:
    ```CoffeeScript
    describe "Chat.hello", ->
      it "starts a conversation", ->
        mock (socket) ->
          socket.expects("connect").args(1234, "localhost")
          chat = new Chat(socket)
          chat.hello("localhost", 1234)
    ```

- Use returns() to specify what a mocked method should return to its caller:
    ```CoffeeScript
    describe "Chat.local_ip_address", ->
      it "returns the ip address of the local end of the chat", ->
        mock (socket) ->
          socket.expects("address")
            .returns( { port: 1234, family: "IPv4", address: "127.0.0.1" } )
          chat = new Chat(socket)
          chat.local_ip_address().should.equal "127.0.0.1"
    ```

- Use throws() to have a mocked method throw an error instead of returning something:
    ```CoffeeScript
    describe "Chat.say", ->
      it "does not eat errors thrown by the underlying socket", ->
        mock (socket) ->
          socket.expects("write").args(123).throws("invalid data")
          chat = new Chat(socket)
          (-> chat.say(123) ).should.throw("invalid data")
    ```

- mock() creates up to five mock objects; here is an example using two:
    ```CoffeeScript
    describe "Chat.say_with_logging", ->
      it "sends a message and also logs it to a file", ->
        mock (socket, fs) ->
          socket.expects("write").args("a message")
          fs.expects("appendFileSync").args("log.txt", "a message")
          chat = new Chat(socket, fs)
          chat.say_with_logging("a message")
    ```

- Source code and supporting files for this Quick Start can be found in the [quick_start](quick_start/) directory.
<br>



### API Reference

- #### args( arg1 [, arg2 ... ] )<br>
  Specifies the arguments that a mocked method should expect.  It takes one or more values:
    ```CoffeeScript
    mocked_object.expects("my_method").args("name", 42)
    ```
  The same method can be specified with different values or different numbers of values:
    ```CoffeeScript
    mocked_object.expects("my_method").args("red")
    mocked_object.expects("my_method").args("blue")   # same signature, different value
    mocked_object.expects("my_method").args(1,2,3)    # different signature
    mocked_object.expects("my_method")                # different signature (no values)
    ```
  args() must be called immediately after expects():
    ```CoffeeScript
    mocked_object.expects("my_method").args(1,2,3)    # ok    
    mocked_object.args(1,2,3).expects("my_method")    # incorrect
    ```
  If a mocked method does not take any arguments, do not use args():
    ```CoffeeScript
    mocked_object.expects("my_method")                # ok
    mocked_object.expects("my_method").args()         # incorrect
    ```
  It is an error to specify duplicate sets of values:
    ```CoffeeScript
    mocked_object.expects("my_method").args(1,2,3)    # ok    
    mocked_object.expects("my_method").args(1,2,3)    # incorrect (duplicate signature)
    ```
  <br>

- #### expects( method_name )<br>
  Adds a method to a mock object.  It takes one string argument, the name of the method:
    ```CoffeeScript
    mocked_object.expects("my_method")
    ```
  <br>
    
- #### returns( value )<br>
  Specifies a value that a mocked method should return when invoked.  It takes one value:
    ```CoffeeScript
    mocked_object.expects("my_method").returns(123)
    ```
  returns() must be called immediately after either expects() or args():
    ```CoffeeScript
    mocked_object.expects("my_method").returns(42)              # ok    
    mocked_object.expects("my_method").args(1,2,3).returns(42)  # ok    
    mocked_object.returns(42).expects("my_method")              # incorrect
    ```
  If a mocked method should not return anything, do not use returns():
    ```CoffeeScript
    mocked_object.expects("my_method")                          # ok
    mocked_object.expects("my_method").returns()                # incorrect
    ```
  <br>

- #### throws( error )<br>
  Specifies a value that a mocked method should throw rather than return.  It takes one value:
    ```CoffeeScript
    mocked_object.expects("my_method").throws( new Errro("an error") )
    ```
  throws() must be called immediately after either expects() or args():
    ```CoffeeScript
    mocked_object.expects("my_method").throws("an error")                 # ok
    mocked_object.expects("my_method").args(1,2,3).throws("an error")     # ok
    mocked_object.throws("an error").expects("my_method")                 # incorrect
    ```
  If a mocked method should not throw anything, do not use throws():
    ```CoffeeScript
    mocked_object.expects("my_method")                                    # ok
    mocked_object.expects("my_method").throws()                           # incorrect
    ```
  returns() and throws() cannot be used at the same time on the same signature:
    ```CoffeeScript
    mocked_object.expects("my_method").returns(123)                       # ok
    mocked_object.expects("my_method").throws("an error")                 # ok
    mocked_object.expects("my_method").returns(123).throws("an error")    # incorrect
    
    mocked_object.expects("your_method").args(1,2,3).returns(42)          # ok
    mocked_onject.expects("your_method").args(4,5,6).throws("an error")   # ok
    ```
  <br>

- #### mock ( mock1 [, mock2 [, mock3 [, mock4 [, mock5 ] ] ] ] ) -><br>
  The mock function takes another function representing a test and runs it, passing it up to five mock objects.  When the function completes, mock checks each of the mock objects to ensure that their expectations were met, throwing an error if this is not the case:
    ```CoffeeScript
    mock (my_mock, your_mock) ->
      my_mock.expects("my_method")
      your_mock.expects("your_method")
      sut = new Sut(my_mock, your_mock)
      sut.do_something_that_uses_the_mocks()
    ```
  Note that mock is a function whose one argument is another function that accepts up to five arguments.  The mock function's parentheses have been omitted for clarity but it does mean that you have to be careful to leave at least one space between 'mock' and the opening parenthesis of the anonymous function argument:
    ```CoffeeScript
    # a strictly correct way
    mock( (m1) ->
      m1.expects("method")
      sut.do_something(m1) )
      
    # can also use a non-anonymous function
    fn = (m1) ->
      m1.expects("method")
      sut.do_something(m1)
    mock(fn)
      
    # a clearer way
    mock (m1) ->
      m1.expects("method")
      sut.do_something(m1)
      
    # but beware
    mock(m1) ->                 # missing a space between 'mock' and '('
      m1.expects("method")
      sut.do_something(m1)
    ```
  <br>

- #### Miscellaneous<br>
  All of the mock methods return the mock instance for [fluency](http://en.wikipedia.org/wiki/Fluent_interface):
    ```CoffeeScript
    # Instead of this:
    mock.expects("my_method")
    mock.args(1,2,3)
    mock.returns("abc")
    mock.expects("your_method")
    mock.args(4,5,6)
    mock.throws("an error")

    # write this:
    mock.expects("my_method").args(1,2,3).returns("abc")
    mock.expects("your_method").args(4,5,6).throws("an error")
    ```
  A mocked method must be called at least once and thereafter can be called any number of times; there is no ability to specify that a method must be called exactly n times:
    ```CoffeeScript
    mock.expects("my_method").args(1,2,3)
    
    # Of course, it would be the system under test that actually makes these calls:
    mock.my_method(1,2,3)   # ok: first time called
    mock.my_method(1,2,3)   # ok: second time called
    mock.my_method(1,2,3)   # and so on
    ```  
    <br>
    


### Further Reading
- [Here](http://en.wikipedia.org/wiki/Mock_object) is a description of mocking.
- [Sinon.JS](http://sinonjs.org) is a complete JavaScript mocking library.
<br>



### Thanks
- [CoffeeScript](http://coffeescript.org), [Markdown](http://daringfireball.net/projects/markdown/)
- [mocha](http://visionmedia.github.io/mocha/), [chai](http://chaijs.com)
- [brackets](http://brackets.io)
- [NodeJS](http://nodejs.org)
- [git](http://git-scm.com), [GitHub](https://github.com)
- [Apple Inc.](http://www.apple.com)
