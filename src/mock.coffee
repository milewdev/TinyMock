class Call
  
  constructor: (args) ->
    @args = args
    @called = false



class Mock

  constructor: ->
    @method_calls = {}
    @last_method_was = undefined
    @last_method_call = undefined
  
  expects: (method_name) ->
    throw new Error("you cannot do my_mock.expects('#{method_name}'); '#{method_name}' is a reserved method name") if method_name in [ "expects", "check" ]
    @last_method_call = new Call()
    @method_calls[ method_name ] = @last_method_call
    @[ method_name ] = (args...) ->
      method_call = @method_calls[ method_name ]    # TODO: use closure?  Memory expensive?
      throw new Error("my_method arguments do not match expectation") if args? and method_call.args? and args != method_call.args
      method_call.called = true
    @last_method_was = "expects"
    @
    
  args: (args...) ->
    throw new Error("you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)") if args.length == 0
    throw new Error(".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)") unless @last_method_was == "expects"
    @last_method_call.args = args
    @last_method_was = "args"
    @
    
  check: ->
    messages = ""
    for method_name, method_call of @method_calls when method_call.called == false
      messages += "'#{method_name}' was never called\n" 
    throw new Error(messages) unless messages == ""
    @last_method_was = "check"
    @

    

mock = (fn) ->
  mocks = ( new Mock() for i in [1..10] )
  fn.apply(undefined, mocks)
  m.check() for m in mocks


    
(exports ? window).mock = mock
(exports ? window).Mock = Mock
