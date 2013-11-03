class Signature
  
  constructor: ->
    @args = []
    @called = false
    @returns = undefined
    
  toString: ->
    @args ? ""



class Mock

  constructor: ->
    @method_calls = {}
    @last_method_name = undefined
    @last_signature = undefined
    @last_method_was = undefined
  
  expects: (method_name) ->
    if method_name in [ "expects", "check" ]
      throw new Error("you cannot do my_mock.expects('#{method_name}'); '#{method_name}' is a reserved method name")
    @last_signature = new Signature()
    @method_calls[ method_name ] ?= []
    @method_calls[ method_name ].push(@last_signature)
    @[ method_name ] = (args...) ->     # TODO: use closure?  Memory expensive?
      method_calls = @method_calls[ method_name ]
      match = undefined
      for signature in @method_calls[ method_name ] 
        if ( signature.args.length == args.length ) and ( signature.args.every ( element, i ) -> element == args[ i ] )
          match = signature
          break
      unless match?
        throw new Error("#{method_name}(#{args}) does not match any expectations") 
      match.called = true
      return match.returns
    @last_method_name = method_name
    @last_method_was = "expects"
    @
    
  args: (args...) ->
    if args.length == 0
      throw new Error("you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)") 
    if @last_method_was != "expects"
      throw new Error(".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)") 
    for signature in @method_calls[ @last_method_name ] 
      if signature.args? and ( signature.args.length == args.length ) and ( signature.args.every ( element, i ) -> element == args[ i ] )
        throw new Error(".expects('#{@last_method_name}').args(#{args}) is a duplicate expectation")
    #if @method_calls[ @last_method_name ].length == 1 and not @method_calls[ @last_method_name ][ 0 ].args?
    #  @method_calls[ @last_method_name ] = []
    @last_signature.args = args
    #@method_calls[ @last_method_name ].push( @last_signature )
    @last_method_was = "args"
    @
    
  returns: (value) ->
    unless value?
      throw new Error("you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)")
    unless @last_method_was in [ "expects", "args" ]
      throw new Error(".returns() must be called immediately after .expects() or .args()")
    @last_signature.returns = value
    @
    
  check: ->
    messages = ""
    for method_name, signatures of @method_calls 
      for signature in signatures when signature.called == false
        messages += "'#{method_name}(#{signature.toString()})' was never called\n" 
    throw new Error(messages) unless messages == ""
    @last_method_was = "check"
    @

    

mock = (fn) ->
  mocks = ( new Mock() for i in [1..10] )
  fn.apply(undefined, mocks)
  m.check() for m in mocks


    
(exports ? window).mock = mock
(exports ? window).Mock = Mock
