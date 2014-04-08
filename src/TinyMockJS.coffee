# TODO: or is it: publish = exports ? this (http://stackoverflow.com/questions/4214731/coffeescript-global-variables/4215132#4215132)
PUBLISH = exports ? window


messages = require("../messages.en.json")


#
# MockFunction
#
class MockFunction
  
  #
  # mock (my_mock) ->
  #   my_mock.expects("my_method")
  #   ...
  #
  PUBLISH.mock = (args...) ->
    try
      _check_mock_usage(args)
      [ expects_method_name, mock_count, test_function ] = _parse_args(args)
      all_expectations = new AllExpectations()    # TODO: use factory method instead of new (same for other classes)
      expects_method = new ExpectsMethod(expects_method_name, all_expectations)
      convenience_mocks = _build_convenience_mock_objects(mock_count)
      _run_test_function(test_function, convenience_mocks)
      all_expectations.verify_all_expectations()
    finally
      expects_method.uninstall_expects_method() if expects_method?  # TODO: the 'if' guard smells?
      all_expectations.uninstall_all_mocked_methods() if all_expectations?
      all_expectations.unregister_all_expectations() if all_expectations?

  # private
  
  _check_mock_usage = (args) ->
    switch args.length
      when 1
        fail(messages.MockUsage) if not is_function(args[0])
      when 2
        fail(messages.MockUsage) if not is_object(args[0])
        fail(messages.MockBadOptions) if not _is_options(args[0])
        fail(messages.MockUsage) if not is_function(args[1])
      else
        fail(messages.MockUsage)

  _is_options = (object) ->
    has_property(object, "expects_method_name") or has_property(object, "mock_count")
      
  _parse_args = (args) ->
    switch args.length
      when 1
        test_function = args[0]
      when 2
        expects_method_name = args[0]["expects_method_name"]
        mock_count = args[0]["mock_count"]
        test_function = args[1]
    [ expects_method_name || "expects", mock_count || 5, test_function ]

  _build_convenience_mock_objects = (mock_count)->
    ( new MockObject() for i in [1..mock_count] )       # => [ mock, mock, ... ]

  _run_test_function = (test_function, convenience_mocks) ->
    test_function.apply(undefined, convenience_mocks)
    
    
#
# MockObject
#
# TODO: explain that Mock is simply a way to distinguish objects 
# created and passed in by mock(), i.e. that in mock (m1, m2),
# methods mocked on m1 and m2 do not already have to exist on
# m1 and m2.
#
class MockObject
  
  # empty


#
# ExpectsMethod
#
#
# Add comment: this functions gets installed to Object.prototype while
# in the scope of the mock() function
#
# mock(my_mock) ->
#   my_mock.expects("my_method")
#
# Note: this is better thought of as a mixin; comment further
#
class ExpectsMethod
  
  constructor: (expects_method_name, all_expectations) ->
    _check_constructor_usage(expects_method_name)
    _install_expects_method(expects_method_name, all_expectations)
    _install_uninstall_expects_method(@, expects_method_name)

  # private
  
  _check_constructor_usage = (expects_method_name) ->
    fail(messages.ExpectsMethodAlreadyExists, expects_method_name) if Object.prototype[ expects_method_name ]?
    
  _install_expects_method = (expects_method_name, all_expectations) ->
    Object.prototype[ expects_method_name ] = (method_name) ->
      _check_expects_usage(@, expects_method_name, method_name)
      _create_expectation(@, method_name, all_expectations)

  # TODO: refactor (hideous name confusion re: expects_method, _install_uninstall_..., etc.)
  _install_uninstall_expects_method = (expects_method, expects_method_name) ->
    expects_method.uninstall_expects_method = -> delete Object.prototype[ expects_method_name ]    

  _check_expects_usage = (object, expects_method_name, method_name) ->
    fail(messages.ExpectsUsage) unless method_name?
    fail(messages.ExpectsReservedMethodName, method_name) if _is_reserved_method_name(expects_method_name, method_name)
    fail(messages.PreExistingProperty, method_name) if has_property(object, method_name)
    fail(messages.NotAnExistingMethod, method_name) if not is_mock_object(object) and not is_class(object) and not does_object_have_method(object, method_name)
    fail(messages.NotAnExistingMethod, method_name) if not is_mock_object(object) and is_class(object) and not does_prototype_have_method(object, method_name)
  
  _create_expectation = (object, method_name, all_expectations) ->
    new Expectation(object, method_name, all_expectations)

  _is_reserved_method_name = (expects_method_name, method_name) ->
    method_name == expects_method_name


#
# AllExpectations
#
# TODO: note about there not being that many expectations (i.e. typically fewer than 10?)
#
# TODO: need to de-singleton this
#
class AllExpectations
  
  constructor: ->
    @_expectations = []
    
  register_expectation: (expectation) ->
    @_expectations.push(expectation)
    
  find_expectation: (object, method_name, args...) ->
    for expectation in @_expectations when expectation.matches(object, method_name, args...)
      return expectation
    fail(messages.UnknownExpectation, method_name, args)

  check_for_duplicate_expectations: ->
    # TODO: use each with index and slice to avoid last element
    return if @_expectations.length < 2
    for outer in [0..@_expectations.length-2]                     # given @_expectations = [ a, b, c ]
      for inner in [outer+1..@_expectations.length-1]             # these loops produce the pairs (a,b), (a,c), (b,c)
        if @_expectations[outer].equals( @_expectations[inner] )
          fail(messages.DuplicateExpectation, @_expectations[outer]._method_name, @_expectations[outer]._args)

  verify_all_expectations: ->
    errors = _find_all_errors(@_expectations)
    throw new Error(errors) unless errors == ""

  # TODO: write comment about uninstalling in reverse
  uninstall_all_mocked_methods: ->
    expectation.uninstall_mocked_method() for expectation in @_expectations by -1
    
  unregister_all_expectations: ->
    @_expectations.length = 0

  # private
  
  _find_all_errors = (all_expectations) ->
      ( expectation.find_errors() for expectation in all_expectations ).join("")
  
  
#
# Expectation
#
class Expectation

  constructor: (object, method_name, all_expectations) ->
    @_object = object
    @_method_name = method_name
    @_args = []
    @_returns = undefined
    @_throws = undefined
    @_called = no
    _install_mock_method(@, all_expectations)
    all_expectations.register_expectation(@)

  args: (args...) ->
    _check_args_usage(@, args...)
    _save_args(@, args)
    @

  returns: (value) ->
    _check_returns_usage(@, value)
    _save_returns(@, value)
    @

  throws: (error) ->
    _check_throws_usage(@, error)
    _save_throws(@, error)
    @

  equals: (other) ->
    @matches(other._object, other._method_name, other._args...)

  matches: (object, method_name, args...) ->
    ( @_method_name == method_name ) and
      ( @_args.length == args.length ) and
      ( @_args.every ( element, i ) -> element == args[ i ] )

  find_errors: ->
    if @_called then "" else format(messages.ExpectationNeverCalled, @_method_name, @_args)

  # private

  _install_mock_method = (expectation, all_expectations) ->
    methods = if is_class(expectation._object) then expectation._object.prototype else expectation._object
    original_method = methods[ expectation._method_name ]
    methods[ expectation._method_name ] = _build_mocked_method(expectation._method_name, all_expectations)
    if original_method?
      expectation.uninstall_mocked_method = -> methods[ expectation._method_name ] = original_method
    else
      expectation.uninstall_mocked_method = -> delete methods[ expectation._method_name ]
  
  _build_mocked_method = (method_name, all_expectations) ->
    (args...) ->
      all_expectations.check_for_duplicate_expectations()    # TODO: explain why we call this here
      _invoke( all_expectations.find_expectation(@, method_name, args...) )
      
  _invoke = (expectation) ->
    expectation._called = yes
    throw expectation._throws if expectation._throws?
    expectation._returns

  _check_args_usage = (expectation, args...) ->
    fail(messages.ArgsUsage) if args.length == 0
    fail(messages.ArgsUsedMoreThanOnce) unless expectation._args.length == 0
    fail(messages.ArgsCalledAfterReturnsOrThrows) if expectation._returns? or expectation._throws?

  _check_returns_usage = (expectation, value) ->
    fail(messages.ReturnsUsage) unless value?
    fail(messages.ReturnsUsedMoreThanOnce) if expectation._returns?
    fail(messages.ReturnsAndThrowsBothUsed) if expectation._throws?

  _check_throws_usage = (expectation, error) ->
    fail(messages.ThrowsUsage) unless error?
    fail(messages.ThrowsUsedMoreThanOnce) if expectation._throws?
    fail(messages.ReturnsAndThrowsBothUsed) if expectation._returns?

  _save_args = (expectation, args) ->
    expectation._args = args

  _save_returns = (expectation, value) ->
    expectation._returns = value

  _save_throws = (expectation, error) ->
    expectation._throws = error


#
# common functions
#

is_class = (object) ->
  typeof object == 'function'
  
is_function = (object) ->
  typeof object == 'function'
  
is_object = (object) ->
  typeof object == 'object'

does_prototype_have_method = (object, method_name) ->
  object.prototype[ method_name ]?
   
does_object_have_method = (object, method_name) ->
  object[ method_name ]?

has_property = (object, property_name) ->
  object[ property_name ]? and (typeof object[ property_name ]) isnt 'function'

is_mock_object = (object) ->
  object.constructor.name == 'MockObject'

fail = (message, args...) ->  
  throw new Error(format(message, args...))

#  
# From http://stackoverflow.com/questions/9880578/coffeescript-version-of-string-format-sprintf-etc-for-javascript-or-node-js
#
format = (message, args...) ->    # format("{0} + {1} = {2}", 2, 2, "four") => "2 + 2 = four"
  message.replace /{(\d)+}/g, (match, i) ->
    if typeof args[i] isnt 'undefined' then args[i] else match
