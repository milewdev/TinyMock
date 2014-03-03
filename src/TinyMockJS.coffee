#
# Expectation represents a mocked method that we expect to be called.  
# It stores the method name, the arguments that we expect to be called 
# with, a value to return or throw, and whether it has actually been 
# called.  For example, the following:
#
#   my_mock = new Mock()
#   expectation = my_mock.expects("my_method").args(1,2,3).returns(42)
#
# would result in a Expectation with @method_name = "my_method",
# @_args = [1,2,3], @_returns = 42, @_throws = undefined, and @called =
# false.  Doing:
#
#   my_mock.my_method(1,2,3)
#
# would result in @called = true.  Note that a mocked method can
# either return a value or throw an error but not both, so either
# @returns or @throws (or both) must be undefined.
#
class Expectation

  constructor: (method_name) ->
    @method_name = method_name
    @_args = []
    @_returns = undefined
    @_throws = undefined
    @called = false

  #
  # my_mock = new Mock()
  # expectation = my_mock.expects("my_method")
  # expectation.args(1,2,3)
  # ...
  #
  # Or more usually:
  #
  # mock (my_mock) ->
  #   my_mock.expects("my_method").args(1,2,3)
  #   ...
  #
  args: (args...) ->
    _check_args_usage(@, args...)
    _save_args(@, args)
    @
    
  #
  # my_mock = new Mock()
  # expectation = my_mock.expects("my_method")
  # expectation.returns(42)
  # ...
  #
  # Or more usually:
  #
  # mock (my_mock) ->
  #   my_mock.expects("my_method").returns(42)
  #   ...
  #
  returns: (value) ->
    _check_returns_usage(@, value)
    _save_returns(@, value)
    @
    
  #
  # my_mock = new Mock()
  # expectation = my_mock.expects("my_method")
  # expectation.throws(new Error("an error"))
  # ...
  #
  # Or more usually:
  #
  # mock (my_mock) ->
  #   my_mock.expects("my_method").throws(new Error("an error"))
  #   ...
  #
  throws: (error) ->
    _check_throws_usage(@, error)
    _save_throws(@, error)
    @

  #
  # Returns true if this exectation equals (has the same values
  # as) another.  For example:
  #
  #   exp1 = new Expectation("my_method")
  #   exp1.args( 1, "a" )
  #
  #   exp2 = new Expectation("my_method")
  #   exp2.args( 1, "a" )
  #
  #   exp1.equals(exp2)           # returns true
  #
  # Note: this method is similar to matches() but is used to
  # find duplicate expectations.
  #
  equals: (other) ->
    @matches(other.method_name, other._args...)

  #
  # Returns true if this expectation has the specified method
  # name and arguments.  For example:
  #
  #   exp = new Expectation("my_method")
  #   exp.args( 1, "a" )
  #   ...
  #   exp.matches( "my_method", [ 1, "a" ] )     # returns true
  #   exp.matches( "your_method", [ 1, "a" ] )   # returns false
  #   exp.matches( "my_method", [ 2, "b" ] )     # returns false
  #
  # Note: this method is similar to equals() but is used to 
  # search for a expectation with a given name and args.
  #
  # TODO: refactor: should @_args be undefined or []?
  matches: (method_name, args...) ->
    ( @method_name == method_name ) and
      ( @_args.length == args.length ) and
      ( @_args.every ( element, i ) -> element == args[ i ] )



#
# Mock represents the mock of some object. @expectations is a list of
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
# is not.  Note that args, returns and throws are optional.  Also 
# note that either returns or throws can be used, but not both on 
# the same expectation.
#
# @expectations is used as a stack only in so far as the method expectation
# at the front of the list is the most recently defined expectation and is
# the one to which args and returns would be applied.  For example:
#
#   my_mock = new Mock()    # @expectations = []
#   my_mock.expects("m1")   # [ { "m1" } ]
#   my_mock.args(1,2,3)     # [ { "m1", [1,2,3] } ]
#   my_mock.returns(42)     # [ { "m1", [1,2,3], 42 } ]
#   my_mock.expects("m2")   # [ { "m2" }, { "m1", [1,2,3], 42 } ]
#   my_mock.args(4,5,6)     # [ { "m2", [4,5,6] }, { "m1", [1,2,3], 42 } ]
#   my_mock.returns(43)     # [ { "m2", [4,5,6], 43 }, { "m1", [1,2,3], 42 } ]
#
# @expectations is just an array, not a hash.  It will not grow very large
# so a linear search for a particular expectation is fine.
#
# @expectations is added to the mock object by the various mock methods when 
# needed (i.e. lazily); if we mock an existing class then we only need to 
# worry about adding the mock methods to that class, not monkeying with its 
# contructor to also add @expectations.
#
class Mock

  #
  # my_mock = new Mock()
  # my_mock.expects("my_method")
  # my_mock.my_method()
  #
  expects: (method_name) ->
    _check_expects_usage(method_name)
    _start_new_expectation(@, method_name)
    _add_method_to_mock(@, method_name)
    _set_state(@, "expects")
    _current_expectation(@)



#
# private
#

_expectations = (mock) ->
  mock.expectations ?= []

_set_state = (mock, state) ->
  mock.state = state

_is_state_in = (mock, states...) ->
  mock.state in states

_is_reserved_word = (word) ->
  word in [ "expects", "args", "returns", "check" ]

_check_expects_usage = (method_name) ->
  _throw_expects_usage() unless method_name?
  _throw_reserved_word(method_name) if _is_reserved_word(method_name)

_check_args_usage = (expectation, args...) ->
  _throw_args_usage() if args.length == 0
  _throw_args_called_more_than_once() unless expectation._args.length == 0

_check_returns_usage = (expectation, value) ->
  _throw_returns_usage() unless value?
  _throw_returns_called_more_than_once() if expectation._returns?
  _throw_returns_and_throws_both_called() if expectation._throws?

_check_throws_usage = (expectation, error) ->
  _throw_throws_usage(error) unless error?
  _throw_throws_called_more_than_once() if expectation._throws?
  _throw_returns_and_throws_both_called() if expectation._returns?

_check_for_duplicate_expectations = (mock) ->
  # TODO: use each with index and slice to avoid last element
  expectations = _expectations(mock)
  return if expectations.length < 2
  for outer in [0..expectations.length-2]
    for inner in [outer+1..expectations.length-1]
      _throw_duplicate_expectation("#{expectations[outer].method_name}(#{expectations[outer]._args})") if expectations[outer].equals( expectations[inner] )

_current_expectation = (mock) ->
  _expectations(mock)[0]

_current_method_name = (mock) ->
  _current_expectation(mock)?.method_name

_find_expectation = (mock, method_name, args...) ->
  for expectation in _expectations(mock) when expectation.matches(method_name, args...)
    return expectation
  undefined

_build_mocked_method = (mock, method_name) ->
  (args...) ->
    expectation = _find_expectation(mock, method_name, args...)
    _throw_unknown_expectation("#{method_name}(#{args})") unless expectation?
    _check_for_duplicate_expectations(mock)
    expectation.called = true
    throw expectation._throws if expectation._throws?
    expectation._returns

_build_errors = (mock) ->
  errors = ""
  for expectation in _expectations(mock) when expectation.called == false
    errors += "'#{expectation.method_name}(#{expectation._args})' was never called\n"
  errors
    
_start_new_expectation = (mock, method_name) ->
  _expectations(mock).unshift( new Expectation(method_name) )     # .unshift pushes to front of array

_add_method_to_mock = (mock, method_name) ->
  mock[ method_name ] ?= _build_mocked_method(mock, method_name)

_save_args = (expectation, args) ->
  expectation._args = args

_save_returns = (expectation, value) ->
  expectation._returns = value
  
_save_throws = (expectation, error) ->
  expectation._throws = error

_throw_expects_usage = ->
  throw "you need to supply a method name to .expects(), e.g. my_mock.expects('my_method')"

_throw_reserved_word = (reserved) ->
  throw "you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name"

_throw_args_usage = ->
  throw "you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)"

_throw_args_called_more_than_once = ->
  throw new Error("you called args() more than once, e.g. my_mock.expects('my_method').args(1).args(2); call it just once")

_throw_duplicate_expectation = (expectation) ->
  throw "#{expectation} is a duplicate expectation"

_throw_returns_usage = ->
  throw "you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)"
  
_throw_returns_called_more_than_once = ->
  throw new Error("you called returns() more than once, e.g. my_mock.expects('my_method').returns(1).returns(2); call it just once")

_throw_throws_usage = ->
  throw "you need to supply an argument to .throws(), e.g. my_mock.expects('my_method').throws('an error')"
  
_throw_throws_called_more_than_once = ->
  throw new Error("you called throws() more than once, e.g. my_mock.expects('my_method').throws('something').throws('something else'); call it just once")

_throw_returns_and_throws_both_called = ->
  throw new Error("you called returns() and throws() on the same expectation; use one or the other but not both")

_throw_unknown_expectation = (expectation) ->
  throw "#{expectation} does not match any expectations"



#
# mock() ensures that _build_errors() is called on mock objects.  It
# takes a function (the test code) argument, creates five mock objects,
# invokes the function with the five mocks, and then calls _build_errors()
# on those mocks, throwing an error if any errors are found.
#
mock = (fn) ->
  mocks = ( new Mock() for i in [1..5] )
  fn.apply(undefined, mocks)
  errors = ( _build_errors(mock) for mock in mocks ).join("")
  throw errors unless errors == ""



root = exports ? window
root.mock = mock
root.Mock = Mock
root.Expectation = Expectation
