class Signature
  
  constructor: ->
    @args = []
    @returns = undefined
    @called = false



class Mock

  constructor: ->
    @method_calls = {}
    @last_method_name = undefined
    @last_signature = undefined
    @last_method_was = undefined
  
  expects: (method_name) ->
    throw_reserved(method_name) if is_reserved(method_name)
    @last_signature = new Signature()
    @method_calls[ method_name ] ?= []
    @method_calls[ method_name ].push(@last_signature)
    @[ method_name ] = (args...) ->     # TODO: use closure?  Memory expensive?
      method_calls = @method_calls[ method_name ]
      for signature in @method_calls[ method_name ] 
        if ( signature.args.length == args.length ) and ( signature.args.every ( element, i ) -> element == args[ i ] )
          signature.called = true
          return signature.returns
      throw_unknown_expectation("#{method_name}(#{args})")
    @last_method_name = method_name
    @last_method_was = "expects"
    @
    
  args: (args...) ->
    throw_args_must_be_after_expects() unless @last_method_was in [ "expects" ]
    throw_args_usage() if args.length == 0
    for signature in @method_calls[ @last_method_name ] 
      if signature.args? and ( signature.args.length == args.length ) and ( signature.args.every ( element, i ) -> element == args[ i ] )
        throw_duplicate_expectation("#{@last_method_name}(#{args})")
    @last_signature.args = args
    @last_method_was = "args"
    @
    
  returns: (value) ->
    throw_returns_must_be_after_expects_or_args() unless @last_method_was in [ "expects", "args" ]
    throw_returns_usage() unless value?
    @last_signature.returns = value
    @last_method_was = "returns"
    @
    
  check: ->
    messages = ""
    for method_name, signatures of @method_calls 
      for signature in signatures when signature.called == false
        messages += "'#{method_name}(#{signature.args})' was never called\n" 
    throw new Error(messages) unless messages == ""
    @last_method_was = "check"
    @
    
  # private
  
  is_reserved = (word) ->
    word in [ "expects", "args", "returns", "check" ]
  
  throw_reserved = (reserved) ->
    throw new Error("you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name")
    
  throw_unknown_expectation = (signature) ->
    throw new Error("#{signature} does not match any expectations")
    
  throw_args_must_be_after_expects = ->
    throw new Error(".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)") 
    
  throw_args_usage = ->
    throw new Error("you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)") 
    
  throw_duplicate_expectation = (signature) ->
    throw new Error("#{signature} is a duplicate expectation")
    
  throw_returns_must_be_after_expects_or_args = ->
    throw new Error(".returns() must be called immediately after .expects() or .args()")
    
  throw_returns_usage = ->
    throw new Error("you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)")

    

mock = (fn) ->
  mocks = ( new Mock() for i in [1..5] )
  fn.apply(undefined, mocks)
  mock.check() for mock in mocks


    
(exports ? window).mock = mock
(exports ? window).Mock = Mock
