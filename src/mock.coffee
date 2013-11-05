# TODO: add description
class MethodSignature
  
  constructor: (method_name) ->
    @method_name = method_name
    @args = []
    @returns = undefined
    @called = false
    
  # TODO: add description
  matches: (method_name, args...) ->
    ( @method_name == method_name ) and
      ( @args.length == args.length ) and
      ( @args.every ( element, i ) -> element == args[ i ] )



# TODO: add description
class Mock

  # TODO: add description
  constructor: ->
    @signatures = []
    @state = undefined
  
  # TODO: add description
  expects: (method_name) ->
    @_check_expects_usage(method_name)
    @signatures.unshift( new MethodSignature(method_name) )     # .unshift pushes to front of array
    @[ method_name ] ?= @_define_expected_method(method_name)
    @_set_state("expects")
    @
    
  # TODO: add description
  args: (args...) ->
    @_check_args_usage(args...)
    @_check_if_duplicate_signature(@_current_method_name(), args...)
    @_current_signature().args = args
    @_set_state("args")
    @
    
  # TODO: add description
  returns: (value) ->
    @_check_returns_usage(value)
    @_current_signature().returns = value
    @_set_state("returns")
    @
    
  # TODO: add description
  check: ->
    @_check_for_uncalled_signatures()
    @_set_state("check")
    @
    
  # private
  
  # TODO: re-order methods below
  
  _current_signature: ->
    @signatures[0]
    
  _current_method_name: ->
    @_current_signature()?.method_name
  
  _find_signature: (method_name, args...) ->
    for signature in @signatures when signature.matches(method_name, args...)
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
    @_throw_args_must_be_after_expects() unless @_is_state_in("expects")
    @_throw_args_usage() if args.length == 0
  
  _check_returns_usage: (value) ->
    @_throw_returns_must_be_after_expects_or_args() unless @_is_state_in("expects", "args")
    @_throw_returns_usage() unless value?
      
  _check_if_duplicate_signature: (method_name, args...) ->
    @_throw_duplicate_expectation("#{method_name}(#{args})") if @_find_signature(method_name, args...)
        
  _check_for_uncalled_signatures: ->
    messages = ""
    for signature in @signatures when signature.called == false
      messages += "'#{signature.method_name}(#{signature.args})' was never called\n" 
    throw messages unless messages == ""
  
  _set_state: (state) ->
    @state = state
    
  _is_state_in: (states...) ->
    @state in states
  
  _is_reserved: (word) ->
    word in [ "expects", "args", "returns", "check" ]
  
  _throw_expects_usage: ->
    throw "you need to supply a method name to .expects(), e.g. my_mock.expects('my_method')"
  
  _throw_reserved: (reserved) ->
    throw "you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name"
    
  _throw_unknown_expectation: (signature) ->
    throw "#{signature} does not match any expectations"
    
  _throw_args_must_be_after_expects: ->
    throw ".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)"
    
  _throw_args_usage: ->
    throw "you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)"
    
  _throw_duplicate_expectation: (signature) ->
    throw "#{signature} is a duplicate expectation"
    
  _throw_returns_must_be_after_expects_or_args: ->
    throw ".returns() must be called immediately after .expects() or .args()"
    
  _throw_returns_usage: ->
    throw "you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)"

    

# TODO: add description
mock = (fn) ->
  mocks = ( new Mock() for i in [1..5] )
  fn.apply(undefined, mocks)
  messages = ""
  for mock in mocks
    try
      mock.check()
    catch ex
      messages += ex
  throw messages unless messages == ""


    
(exports ? window).mock = mock
(exports ? window).Mock = Mock
