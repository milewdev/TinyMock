#
# MethodSignature is an internal data structure that represents 
# a mocked method.  Stores the method name, the expected arguments,
# the value to return, and whether it has actually been called.
# For example, the following:
#
#   my_mock = (new Mock).expects("my_method").args(1,2,3).returns(42)
#
# would result in a MethodSignature with @method_name = "my_method",
# @args = [1,2,3], @returns = 42, and @called = false.  Doing:
#
#   my_mock.my_method(1,2,3)
#
# would result in @called = true.
#
class MethodSignature
  
  constructor: (method_name) ->
    @method_name = method_name
    @args = []
    @returns = undefined
    @called = false
    
  #
  # Returns true if this signature has the specified method
  # name and arguments.  For example:
  #
  #   ms = new MethodSignature("my_method")
  #   ms.args = [ 1, "a" ]
  #   ...
  #   ms.matches( "my_method", [ 1, "a" ] )     # returns true
  #   ms.matches( "your_method", [ 1, "a" ] )   # returns false
  #   ms.matches( "my_method", [ 2, "b" ] )     # returns false
  #
  matches: (method_name, args...) ->
    ( @method_name == method_name ) and
      ( @args.length == args.length ) and
      ( @args.every ( element, i ) -> element == args[ i ] )



#
# Mock represents the mock of some object.  @signatures is a list of
# mocked methods, which are added with the .expects(), .args(), and 
# .returns() functions.  These must be called in a specific order,
# expects then args then returns, so:
#
#   my_mock.expects("my_method").args(123).returns(456)
#
# is legal, whereas:
#
#   my_mock.returns(456).args(123).expects("my_method")
#
# is not.  @state is used to remember the last function called so that
# we can enforce this order.  Note that args and returns are optional.
#
# @signatures is used as a stack only in so far as the method signature
# at the front of the list is the most recently defined signature and is
# the one to which args and returns would be applied.  For example:
#
#   my_mock = new Mock()    # @signatures = []
#   my_mock.expects("m1")   # [ { "m1" } ]
#   my_mock.args(1,2,3)     # [ { "m1", [1,2,3] } ]
#   my_mock.returns(42)     # [ { "m1", [1,2,3], 42 } ]
#   my_mock.expects("m2")   # [ { "m2" }, { "m1", [1,2,3], 42 } ]
#   my_mock.args(4,5,6)     # [ { "m2", [4,5,6] }, { "m1", [1,2,3], 42 } ]
#   my_mock.returns(43)     # [ { "m2", [4,5,6], 43 }, { "m1", [1,2,3], 42 } ]
#
# @signatures is just an array, not a hash.  It will not grow very large
# so a linear search for a particular signature is fine.
#
class Mock

  constructor: ->
    @signatures = []
    @state = undefined
  
  #
  # my_mock = (new Mock).expects("my_method")
  # my_mock.my_method()
  #
  expects: (method_name) ->
    @_check_expects_usage(method_name)
    @signatures.unshift( new MethodSignature(method_name) )     # .unshift pushes to front of array
    @[ method_name ] ?= @_define_expected_method(method_name)
    @_set_state("expects")
    @
    
  #
  # my_mock = (new Mock).expects("my_method").args(1,2,3)
  # my_mock.my_method(1,2,3)
  #
  args: (args...) ->
    @_check_args_usage(args...)
    @_check_if_duplicate_signature(@_current_method_name(), args...)
    @_current_signature().args = args
    @_set_state("args")
    @
    
  #
  # my_mock = (new Mock).expects("my_method").returns(123)
  # console.log my_mock.my_method()   # prints 123
  #
  returns: (value) ->
    @_check_returns_usage(value)
    @_current_signature().returns = value
    @_set_state("returns")
    @
    
  #
  # my_mock = (new Mock).expects("my_method").expects("your_method")
  # my_mock.my_method()
  # my_mock.check()       # throws an error because your_method() was not called
  #
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

    

#
# mock() is a shorthand function to ensure that .check() is called 
# on mock objects.  As such, it takes a function (the test code)
# argument, creates five mock objects, invokes the function with
# the five mocks, and then calls check() on the mocks.
#
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
