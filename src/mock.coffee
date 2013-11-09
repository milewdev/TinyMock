#
# MethodSignature is an internal data structure that represents 
# a mocked method.  Stores the method name, the expected arguments,
# the value to return or throw, and whether it has actually been 
# called.  For example, the following:
#
#   my_mock = (new Mock).expects("my_method").args(1,2,3).returns(42)
#
# would result in a MethodSignature with @method_name = "my_method",
# @args = [1,2,3], @returns = 42, @throws = undefined, and @called = 
# false.  Doing:
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
    @throws = undefined
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
# mocked methods, which are added with the .expects(), .args(), 
# .returns(), and .throws() functions.  These must be called in a 
# specific order, expects then args then returns or throws, so:
#
#   my_mock.expects("my_method").args(123).returns(456)
#
# is legal, whereas:
#
#   my_mock.returns(456).args(123).expects("my_method")
#
# is not.  @state is used to remember the last function called so that
# we can enforce this order.  Note that args, returns and throws are 
# optional.  Also note that either returns or throws can be used, but
# not both on the same signature.
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
    @[ method_name ] ?= @_build_mocked_method(method_name)
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
  # my_mock = (new Mock).expects("my_method").throws("an error")
  # try
  #   my_mock.my_method()
  # catch error
  #   console.log error   # prints "an error"
  #
  throws: (error) ->
    @_check_throws_usage(error)
    @_current_signature().throws = error
    @_set_state("throws")
    @
    
  #
  # my_mock = (new Mock).expects("my_method").expects("your_method")
  # my_mock.my_method()
  # my_mock.check()       # throws an error because your_method() was not called
  #
  check: ->
    @_set_state("check")
    @_check_for_errors()
    @
    
  # private
  
  _current_signature: ->
    @signatures[0]
    
  _current_method_name: ->
    @_current_signature()?.method_name
  
  _find_signature: (method_name, args...) ->
    for signature in @signatures when signature.matches(method_name, args...)
      return signature
    undefined
  
  _build_mocked_method: (method_name) ->
    (args...) ->
      signature = @_find_signature(method_name, args...)
      @_throw_unknown_expectation("#{method_name}(#{args})") unless signature?
      signature.called = true
      throw signature.throws if signature.throws?
      signature.returns
  
  _build_errors: ->
    errors = ""
    for signature in @signatures when signature.called == false
      errors += "'#{signature.method_name}(#{signature.args})' was never called\n" 
    errors
  
  _set_state: (state) ->
    @state = state
    
  _is_state_in: (states...) ->
    @state in states
  
  _is_reserved_word: (word) ->
    word in [ "expects", "args", "returns", "check" ]
  
  _check_expects_usage: (method_name) ->
    @_throw_expects_usage() unless method_name?
    @_throw_reserved_word(method_name) if @_is_reserved_word(method_name)
  
  _check_args_usage: (args...) ->
    @_throw_args_usage() if args.length == 0
    @_throw_args_must_be_after_expects() unless @_is_state_in("expects")
  
  _check_returns_usage: (value) ->
    @_throw_returns_usage() unless value?
    @_throw_returns_must_be_after_expects_or_args() unless @_is_state_in("expects", "args")
      
  _check_throws_usage: (error) ->
    @_throw_throws_usage(error) unless error?
    @_throw_throws_must_be_after_expects_or_args() unless @_is_state_in("expects", "args")
      
  _check_if_duplicate_signature: (method_name, args...) ->
    @_throw_duplicate_expectation("#{method_name}(#{args})") if @_find_signature(method_name, args...)
        
  _check_for_errors: ->
    errors = @_build_errors()
    throw errors unless errors == ""
  
  _throw_expects_usage: ->
    throw "you need to supply a method name to .expects(), e.g. my_mock.expects('my_method')"
  
  _throw_reserved_word: (reserved) ->
    throw "you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name"
    
  _throw_args_usage: ->
    throw "you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)"
    
  _throw_args_must_be_after_expects: ->
    throw ".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)"
    
  _throw_duplicate_expectation: (signature) ->
    throw "#{signature} is a duplicate expectation"
    
  _throw_returns_usage: ->
    throw "you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)"
    
  _throw_returns_must_be_after_expects_or_args: ->
    throw ".returns() must be called immediately after .expects() or .args()"
    
  _throw_throws_usage: ->
    throw "you need to supply an argument to .throws(), e.g. my_mock.expects('my_method').throws('an error')"
    
  _throw_throws_must_be_after_expects_or_args: ->
    throw ".throws() must be called immediately after .expects() or .args()"
    
  _throw_unknown_expectation: (signature) ->
    throw "#{signature} does not match any expectations"

    

#
# mock() is a convenience function to ensure that _build_errors() is
# called on mock objects.  As such, it takes a function (the test code)
# argument, creates five mock objects, invokes the function with the
# five mocks, and then calls _build_errors() on those mocks, throwing an
# error if any errors are found.
#
# _build_errors() is a "private" method on Mocks; check() should really
# be used but it results in a try/catch block and messier code.  Could
# make _build_errors() public.
#
mock = (fn) ->
  mocks = ( new Mock() for i in [1..5] )
  fn.apply(undefined, mocks)
  errors = ( mock._build_errors() for mock in mocks ).join("")
  throw errors unless errors == ""


    
(exports ? window).mock = mock
(exports ? window).Mock = Mock
