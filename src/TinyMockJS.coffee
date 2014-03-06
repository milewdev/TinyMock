publish = exports ? window


#
# mock()
#
publish.mock = (test_function) ->
  try
    install_expects_method()
    convenience_mocks = build_convenience_mock_objects()
    run_test_function(test_function, convenience_mocks)
    verify_all_expectations()
  finally
    uninstall_expects_method()
    uninstall_all_mocked_methods()
    clear_all_expectations()

install_expects_method = ->
  Object.prototype.expects = expects

uninstall_expects_method = ->
  delete Object.prototype.expects

uninstall_all_mocked_methods = ->
  for expectation in all_expectations     # TODO: do this in reverse
    object = if typeof expectation._object == 'function' then expectation._object.prototype else expectation._object
    if expectation._original_method?
      object[ expectation.method_name ] = expectation._original_method
    else
      delete object[ expectation.method_name ]

build_convenience_mock_objects = ->
  ( new Object() for i in [1..5] )

run_test_function = (test_function, convenience_mocks) ->
  test_function.apply(undefined, convenience_mocks)


#
# expects
#
expects = (method_name) ->
  _check_expects_usage(method_name)
  if @[ method_name ]? and typeof @[ method_name ] != 'function'
    throw new Error("'#{method_name}' is an existing property; you can only mock functions")
  if typeof @ == 'function' and not @.prototype[ method_name ]?
    throw new Error("'#{method_name}' is not an existing method; you can only mock existing methods on classes")
  _start_new_expectation(@, method_name)

_check_expects_usage = (method_name) ->
  _throw_expects_usage() unless method_name?
  _throw_reserved_word(method_name) if _is_reserved_word(method_name)

_is_reserved_word = (word) ->
  word in [ "expects", "args", "returns", "check" ]

_throw_expects_usage = ->
  throw "you need to supply a method name to expects(), e.g. my_mock.expects('my_method')"

_throw_reserved_word = (reserved) ->
  throw "you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name"

_start_new_expectation = (object, method_name) ->
  new Expectation(object, method_name)


#
# all_expectations
#
all_expectations = []

clear_all_expectations = ->
  all_expectations.length = 0

verify_all_expectations = ->
  errors = build_errors()
  throw new Error(errors) unless errors == ""

build_errors = ->
  (build_not_called_error(expectation) for expectation in all_expectations when not expectation.called).join("")

build_not_called_error = (expectation) ->
  "'#{expectation.method_name}(#{expectation._args})' was never called\n"
  
  
#
# mocked_method
#
build_mocked_method = (method_name) ->
  (args...) ->
    expectation = find_expectation(@, method_name, args...)
    throw_unknown_expectation("#{method_name}(#{args})") unless expectation?
    check_for_duplicate_expectations()
    expectation.called = yes
    throw expectation._throws if expectation._throws?
    expectation._returns

find_expectation = (object, method_name, args...) ->
  for expectation in all_expectations when expectation.matches(object, method_name, args...)
    return expectation
  undefined

check_for_duplicate_expectations = ->
  # TODO: use each with index and slice to avoid last element
  return if all_expectations.length < 2
  for outer in [0..all_expectations.length-2]
    for inner in [outer+1..all_expectations.length-1]
      if all_expectations[outer].equals( all_expectations[inner] )
        throw_duplicate_expectation("#{all_expectations[outer].method_name}(#{all_expectations[outer]._args})")

throw_unknown_expectation = (expectation) ->
  throw "#{expectation} does not match any expectations"

throw_duplicate_expectation = (expectation) ->
  throw "#{expectation} is a duplicate expectation"


#
# Expectation
#
class Expectation

  constructor: (object, method_name) ->
    @_object = object
    @method_name = method_name
    @_args = []
    @_returns = undefined
    @_throws = undefined
    @called = false
    @_original_method = undefined
    _install_mock_method(@, object, method_name)
    all_expectations.push(@)

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
  # mock (my_mock) ->
  #   my_mock.expects("my_method").returns(42)
  #   ...
  #
  returns: (value) ->
    _check_returns_usage(@, value)
    _save_returns(@, value)
    @

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
  # Note: this method is similar to matches() but is used to
  # find duplicate expectations.
  #
  equals: (other) ->
    @matches(other._object, other.method_name, other._args...)

  #
  # Note: this method is similar to equals() but is used to
  # search for a expectation with a given name and args.
  #
  # TODO: refactor: should @_args be undefined or []?
  matches: (object, method_name, args...) ->
    ( @method_name == method_name ) and
      ( @_args.length == args.length ) and
      ( @_args.every ( element, i ) -> element == args[ i ] )


# private

_check_args_usage = (expectation, args...) ->
  _throw_args_usage() if args.length == 0
  _throw_args_used_more_than_once() unless expectation._args.length == 0

_check_returns_usage = (expectation, value) ->
  _throw_returns_usage() unless value?
  _throw_returns_used_more_than_once() if expectation._returns?
  _throw_returns_and_throws_both_used() if expectation._throws?

_check_throws_usage = (expectation, error) ->
  _throw_throws_usage(error) unless error?
  _throw_throws_used_more_than_once() if expectation._throws?
  _throw_returns_and_throws_both_used() if expectation._returns?

_save_args = (expectation, args) ->
  expectation._args = args

_save_returns = (expectation, value) ->
  expectation._returns = value

_save_throws = (expectation, error) ->
  expectation._throws = error

_install_mock_method = (expectation, object, method_name) ->
  if typeof object == 'function'
    expectation._original_method = object.prototype[ method_name ]
    object.prototype[ method_name ] = build_mocked_method(method_name)
  else
    expectation._original_method = object[ method_name ]
    object[ method_name ] = build_mocked_method(method_name)

_throw_args_usage = ->
  throw "you need to supply at least one argument to args(), e.g. my_mock.expects('my_method').args(42)"

_throw_args_used_more_than_once = ->
  throw new Error("you specified args() more than once, e.g. my_mock.expects('my_method').args(1).args(2); use it once per expectation")

_throw_returns_usage = ->
  throw "you need to supply an argument to returns(), e.g. my_mock.expects('my_method').returns(123)"

_throw_returns_used_more_than_once = ->
  throw new Error("you specified returns() more than once, e.g. my_mock.expects('my_method').returns(1).returns(2); use it once per expectation")

_throw_throws_usage = ->
  throw "you need to supply an argument to throws(), e.g. my_mock.expects('my_method').throws('an error')"

_throw_throws_used_more_than_once = ->
  throw new Error("you specified throws() more than once, e.g. my_mock.expects('my_method').throws('something').throws('something else'); use it once per expectation")

_throw_returns_and_throws_both_used = ->
  throw new Error("you specified both returns() and throws() on the same expectation; use one or the other on an expectation")
