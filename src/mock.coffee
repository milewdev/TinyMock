class Signature
  
  constructor: (method_name) ->
    @method_name = method_name
    @args = []
    @returns = undefined
    @called = false



class Mock

  constructor: ->
    @method_calls = {}
    @current_signature = undefined
    @state = undefined
  
  expects: (method_name) ->
    @_check_expects_usage(method_name)
    @current_signature = new Signature(method_name)
    @method_calls[ method_name ] ?= []
    @method_calls[ method_name ].push(@current_signature)
    @[ method_name ] = @_define_expected_method(method_name)
    @_set_state("expects")
    @
    
  args: (args...) ->
    @_check_args_usage(args...)
    @_check_for_duplicate_signature(args...)
    @current_signature.args = args
    @_set_state("args")
    @
    
  returns: (value) ->
    @_check_returns_usage(value)
    @current_signature.returns = value
    @_set_state("returns")
    @
    
  check: ->
    @_check_for_uncalled_signatures()
    @_set_state("check")
    @
    
  # private
  
  _find_signature: (method_name, args...) ->
    for signature in @method_calls[ method_name ]
      if ( signature.args.length == args.length ) and ( signature.args.every ( element, i ) -> element == args[ i ] )
        return signature
    undefined
  
  _define_expected_method: (method_name) ->
    (args...) ->
      signature = @_find_signature(method_name, args...)
      @_throw_unknown_expectation("#{method_name}(#{args})") unless signature?
      signature.called = true
      signature.returns
  
  _check_expects_usage: (method_name) ->
    @_throw_expects_usage() unless method_name?
    @_throw_reserved(method_name) if @_is_reserved(method_name)
  
  _check_args_usage: (args...) ->
    @_throw_args_must_be_after_expects() unless @_state_in("expects")
    @_throw_args_usage() if args.length == 0
  
  _check_returns_usage: (value) ->
    @_throw_returns_must_be_after_expects_or_args() unless @_state_in("expects", "args")
    @_throw_returns_usage() unless value?
      
  _check_for_duplicate_signature: (args...) ->
    @_throw_duplicate_expectation("#{@current_signature.method_name}(#{args})") if @_find_signature(@current_signature.method_name, args...)
        
  _check_for_uncalled_signatures: ->
    messages = ""
    for method_name, signatures of @method_calls 
      for signature in signatures when signature.called == false
        messages += "'#{method_name}(#{signature.args})' was never called\n" 
    throw new Error(messages) unless messages == ""
  
  _set_state: (state) ->
    @state = state
    
  _state_in: (states...) ->
    @state in states
  
  _is_reserved: (word) ->
    word in [ "expects", "args", "returns", "check" ]
  
  _throw_expects_usage: ->
    throw new Error("you need to supply a method name to .expects(), e.g. my_mock.expects('my_method')")
  
  _throw_reserved: (reserved) ->
    throw new Error("you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name")
    
  _throw_unknown_expectation: (signature) ->
    throw new Error("#{signature} does not match any expectations")
    
  _throw_args_must_be_after_expects: ->
    throw new Error(".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)") 
    
  _throw_args_usage: ->
    throw new Error("you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)") 
    
  _throw_duplicate_expectation: (signature) ->
    throw new Error("#{signature} is a duplicate expectation")
    
  _throw_returns_must_be_after_expects_or_args: ->
    throw new Error(".returns() must be called immediately after .expects() or .args()")
    
  _throw_returns_usage: ->
    throw new Error("you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)")

    

mock = (fn) ->
  mocks = ( new Mock() for i in [1..5] )
  fn.apply(undefined, mocks)
  mock.check() for mock in mocks


    
(exports ? window).mock = mock
(exports ? window).Mock = Mock
