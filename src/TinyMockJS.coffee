# TODO: or is it: publish = exports ? this (http://stackoverflow.com/questions/4214731/coffeescript-global-variables/4215132#4215132)
PUBLISH = exports ? window


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
      ExpectsMethod.install_expects_method(expects_method_name)
      convenience_mocks = _build_convenience_mock_objects()
      _run_test_function(test_function, convenience_mocks)
      AllExpectations.verify_all_expectations()
    finally
      ExpectsMethod.uninstall_expects_method()
      AllExpectations.uninstall_all_mocked_methods()
      AllExpectations.unregister_all_expectations()

  # private
  
  _check_mock_usage = (args) ->
    _throw_usage() unless 1 <= args.length <= 2
    _throw_usage() if args.length == 1 and not (typeof args[0] == 'function')
    _throw_usage() if args.length == 2 and not (typeof args[0] == 'object')
    _throw_usage() if args.length == 2 and not (typeof args[1] == 'function')
    _throw_bad_options(args[0]) if args.length == 2 and not does_object_have_property(args[0], "expects_method_name") and not does_object_have_property(args[0], "mock_count")
    
  _parse_args = (args) ->
    if args.length == 1
      test_function = args[0]
    else
      expects_method_name = args[0]["expects_method_name"]
      mock_count = args[0]["mock_count"]
      test_function = args[1]
    [ expects_method_name || "expects", mock_count || 5, test_function ]

  _build_convenience_mock_objects = ->
    ( new MockObject() for i in [1..5] )      # => [ mock, mock, ... ]

  _run_test_function = (test_function, convenience_mocks) ->
    test_function.apply(undefined, convenience_mocks)
    
  _throw_usage = ->
    throw new Error("you need to pass either a function, or options and a function, to mock(), e.g. mock expects_method_name: 'exp', (m) -> m.expects('my_method') ...")
    
  _throw_bad_options = (options) ->
    attributes = (key for key of options).join(", ")
    throw new Error("the options argument should have attributes expects_method_name or mock_count; found attributes: #{attributes}")
    
    
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
# Note: this is better thought of as a mixin; comment further
#
class ExpectsMethod
  
  @install_expects_method: (expects_method_name) ->
    # TODO: throw an exception if Object.prototype already has a method called expects_method_name
    Object.prototype[ expects_method_name ] = (method_name) ->
      _check_expects_usage(@, expects_method_name, method_name)
      _create_expectation(@, method_name)
    # TODO: need to dynamically generate uninstall_expects_method so that it deletes the correct method; not sure where to hang it.
    # TODO: need to dynamically generate 'expects' method so that it correctly does the _check_expects_usage.
    # TODO: can we convert AllExpectations to be non-singleton and hang it off of the mock() method?

  @uninstall_expects_method: ->
    delete Object.prototype.expects
  
  #
  # this functions gets installed to Object.prototype while
  # in the scope of the mock() function
  #
  # mock(my_mock) ->
  #   my_mock.expects("my_method")
  #
  #expects = (method_name) ->
  #  _check_expects_usage(@, method_name)
  #  _create_expectation(@, method_name)

  # private

  _check_expects_usage = (object, expects_method_name, method_name) ->
    _throw_expects_usage() unless method_name?
    _throw_reserved_method_name(method_name) if _is_reserved_method_name(expects_method_name, method_name)
    _throw_pre_existing_property(method_name) if does_object_have_property(object, method_name)
    _throw_not_an_existing_method(method_name) if not is_mock_object(object) and not is_class(object) and not does_object_have_method(object, method_name)
    _throw_not_an_existing_method(method_name) if not is_mock_object(object) and is_class(object) and not does_prototype_have_method(object, method_name)
  
  _create_expectation = (object, method_name) ->
    new Expectation(object, method_name)

  _is_reserved_method_name = (expects_method_name, method_name) ->
    method_name == expects_method_name

  _throw_expects_usage = ->
    throw new Error( "you need to supply a method name to expects(), e.g. my_mock.expects('my_method')" )

  _throw_reserved_method_name = (reserved_method_name) ->
    throw new Error( "you cannot use my_mock.#{reserved_method_name}('#{reserved_method_name}'); '#{reserved_method_name}' is a reserved method name" )
  
  _throw_pre_existing_property = (property_name) ->
    throw new Error( "'#{property_name}' is an existing property; you can only mock functions" )
  
  _throw_not_an_existing_method = (method_name) ->
    throw new Error( "'#{method_name}' is not an existing method; you can only mock existing methods on objects (or classes) not passed in by mock()" )


#
# AllExpectations
#
# TODO: note about there not being that many expectations (i.e. typically fewer than 10?)
#
class AllExpectations
  
  @register_expectation: (expectation) ->
    _expectations.push(expectation)
    
  @find_expectation_that_matches: (object, method_name, args...) ->
    for expectation in _expectations when expectation.matches(object, method_name, args...)
      return expectation
    undefined

  @check_for_duplicate_expectations: ->
    # TODO: use each with index and slice to avoid last element
    return if _expectations.length < 2
    for outer in [0.._expectations.length-2]                     # given _expectations = [ a, b, c ]
      for inner in [outer+1.._expectations.length-1]             # these loops produce the pairs (a,b), (a,c), (b,c)
        if _expectations[outer].equals( _expectations[inner] )
          _throw_duplicate_expectation("#{_expectations[outer]._method_name}(#{_expectations[outer]._args})")

  @verify_all_expectations: ->
    errors = _find_all_errors()
    throw new Error(errors) unless errors == ""

  # TODO: write comment about uninstalling in reverse
  @uninstall_all_mocked_methods: ->
    expectation.uninstall_mocked_method() for expectation in _expectations by -1
    
  @unregister_all_expectations: ->
    _expectations.length = 0
    
  # private
  
  _expectations = []
  
  _find_all_errors = ->
      ( expectation.find_errors() for expectation in _expectations ).join("")

  _throw_duplicate_expectation = (expectation) ->
    throw new Error( "#{expectation} is a duplicate expectation" )
  
  
#
# MockedMethodBuilder
#
class MockedMethodBuilder
  
  @build_mocked_method: (method_name) ->
    (args...) ->
      expectation = AllExpectations.find_expectation_that_matches(@, method_name, args...)
      _throw_unknown_expectation(method_name, args) unless expectation?
      AllExpectations.check_for_duplicate_expectations()
      expectation._called = yes
      throw expectation._throws if expectation._throws?
      expectation._returns

  # private
  
  _throw_unknown_expectation = (method_name, args) ->
    throw new Error( "#{method_name}(#{args}) does not match any expectations" )


#
# Expectation
#
class Expectation

  constructor: (object, method_name) ->
    @_object = object
    @_method_name = method_name
    @_args = []
    @_returns = undefined
    @_throws = undefined
    @_called = no
    _install_mock_method(@)
    AllExpectations.register_expectation(@)

  #
  # mock (mock) ->
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
    @matches(other._object, other._method_name, other._args...)

  #
  # Note: this method is similar to equals() but is used to
  # search for a expectation with a given name and args.
  #
  # TODO: refactor: should @_args be undefined or []?
  matches: (object, method_name, args...) ->
    ( @_method_name == method_name ) and
      ( @_args.length == args.length ) and
      ( @_args.every ( element, i ) -> element == args[ i ] )

  find_errors: ->
    if not @_called then "'#{@_method_name}(#{@_args})' was never called\n" else ""

  # private

  _check_args_usage = (expectation, args...) ->
    _throw_args_usage() if args.length == 0
    _throw_args_used_more_than_once() unless expectation._args.length == 0

  _check_returns_usage = (expectation, value) ->
    _throw_returns_usage() unless value?
    _throw_returns_used_more_than_once() if expectation._returns?
    _throw_returns_and_throws_both_used() if expectation._throws?

  _check_throws_usage = (expectation, error) ->
    _throw_throws_usage() unless error?
    _throw_throws_used_more_than_once() if expectation._throws?
    _throw_returns_and_throws_both_used() if expectation._returns?

  _save_args = (expectation, args) ->
    expectation._args = args

  _save_returns = (expectation, value) ->
    expectation._returns = value

  _save_throws = (expectation, error) ->
    expectation._throws = error

  _install_mock_method = (expectation) ->
    methods = if is_class(expectation._object) then expectation._object.prototype else expectation._object
    original_method = methods[ expectation._method_name ]
    methods[ expectation._method_name ] = MockedMethodBuilder.build_mocked_method(expectation._method_name)
    if original_method?
      expectation.uninstall_mocked_method = -> methods[ expectation._method_name ] = original_method
    else
      expectation.uninstall_mocked_method = -> delete methods[ expectation._method_name ]

  _throw_args_usage = ->
    throw new Error( "you need to supply at least one argument to args(), e.g. my_mock.expects('my_method').args(42)" )

  _throw_args_used_more_than_once = ->
    throw new Error( "you specified args() more than once, e.g. my_mock.expects('my_method').args(1).args(2); use it once per expectation" )

  _throw_returns_usage = ->
    throw new Error( "you need to supply an argument to returns(), e.g. my_mock.expects('my_method').returns(123)" )

  _throw_returns_used_more_than_once = ->
    throw new Error( "you specified returns() more than once, e.g. my_mock.expects('my_method').returns(1).returns(2); use it once per expectation" )

  _throw_throws_usage = ->
    throw new Error( "you need to supply an argument to throws(), e.g. my_mock.expects('my_method').throws('an error')" )

  _throw_throws_used_more_than_once = ->
    throw new Error( "you specified throws() more than once, e.g. my_mock.expects('my_method').throws('something').throws('something else'); use it once per expectation" )

  _throw_returns_and_throws_both_used = ->
    throw new Error( "you specified both returns() and throws() on the same expectation; use one or the other on an expectation" )


#
# common functions
#

is_class = (object) ->
  typeof object == 'function'

does_prototype_have_method = (object, method_name) ->
  object.prototype[ method_name ]?
   
does_object_have_method = (object, method_name) ->
  object[ method_name ]?

does_object_have_property = (object, method_name) ->
  object[ method_name ]? and (typeof object[ method_name ]) != 'function'

is_mock_object = (object) ->
  object.constructor.name == 'MockObject'
