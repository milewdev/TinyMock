# TODO: In error message names: Called, Used, or Specified: pick one
messages = require("../messages/messages.en.json")



mock = (args...) ->
  fail(messages.MockUsage) if args.length < 1 or 2 < args.length
  fail(messages.MockUsage) if args.length == 1 and ! is_function(args[0])
  fail(messages.MockUsage) if args.length == 2 and ! is_function(args[1])
  fail(messages.MockBadUsage) if args.length == 2 and ! has_property(args[0], "expects_method_name") and ! has_property(args[0], "mock_count")
  test_function = ( if args.length == 1 then args[0] else args[1] )
  expects_method_name = ( if args.length == 2 then args[0].expects_method_name ) ? "expects"    # TODO: use merge idiom?  what happens if expects_method_name is not a valid method name?
  mock_count = ( if args.length == 2 then args[0].mock_count ) ? 5                              # TODO: what happens if mock_count is not a number?
  fail(messages.ExpectsMethodAlreadyExists, expects_method_name) if Object.prototype[expects_method_name]?
  mock_objects = ( new MockObject() for i in [1..mock_count] )
  mock_methods = new MockMethodList()
  Object.prototype[expects_method_name] = (method_name) ->
    fail(messages.ExpectsUsage) unless method_name?
    fail(messages.ExpectsUsage) if arguments.length != 1
    fail(messages.NotAnExistingMethod, method_name) unless is_mock_object(@) or has_method(@, method_name)
    fail(messages.PreExistingProperty, method_name) if has_property(@, method_name)
    fail(messages.ReservedMethodName, method_name) if method_name == expects_method_name        # TODO: extract is_reserved_method_name()
    expectations = @[method_name]?.expectations
    if ! expectations
      mock_method = (args...) ->
        expectations.check_for_duplicate_expectations(method_name)                              # TODO: explain why we do this here
        expectation = expectations.find_expectation(args...)
        fail(messages.UnknownExpectation, method_name, args) unless expectation
        expectation._called = yes
        throw expectation._throws if expectation._throws
        expectation._returns
      mock_method.object = @
      mock_method.method_name = method_name
      mock_method.original_method = @[method_name]
      mock_method.expectations = expectations = new ExpectationList()
      mock_method.restore_original_method = ->
        if @original_method?
          @object[@method_name] = @original_method
        else
          delete @object[@method_name]
      mock_method.find_errors = ->
        @expectations.find_errors(@method_name)
      @[method_name] = mock_method
      mock_methods.add(mock_method)
    expectations.create_expectation()
  try
    test_function.apply(null, mock_objects)
    errors = mock_methods.find_errors()
    fail( errors.join("\n") + "\n" ) unless errors.length == 0
  finally
    mock_methods.restore_original_methods()
    delete Object.prototype[expects_method_name]



class MockObject

  # empty



class Expectation

  constructor: ->
    @_args = []
    @_returns = undefined
    @_throws = undefined
    @_called = no

  args: (args...) ->
    _check_args_usage(@, args)
    @_args = args
    @

  returns: (value) ->
    _check_returns_usage(@, value, arguments.length)
    @_returns = value
    @

  throws: (error) ->
    _check_throws_usage(@, error, arguments.length)
    @_throws = error
    @

  # is this expectation the same as that other one
  equals: (other) ->
    @matches(other._args...)

  # does this expectation have those args
  matches: (args...) ->
    ( @_args.length == args.length ) and
      ( @_args.every ( element, i ) -> element == args[ i ] )

  # private

  _check_args_usage = (self, args) ->
    fail(messages.ArgsUsage) if args.length == 0
    fail(messages.ArgsUsedMoreThanOnce) unless self._args.length == 0
    fail(messages.ArgsUsedAfterReturnsOrThrows) if self._returns? or self._throws?

  _check_returns_usage = (self, value, arg_count) ->
    fail(messages.ReturnsUsage) unless value?
    fail(messages.ReturnsUsage) if arg_count != 1
    fail(messages.ReturnsUsedMoreThanOnce) if self._returns?
    fail(messages.ReturnsAndThrowsBothUsed) if self._throws?

  _check_throws_usage = (self, error, arg_count) ->
    fail(messages.ThrowsUsage) unless error?
    fail(messages.ThrowsUsage) if arg_count != 1
    fail(messages.ThrowsUsedMoreThanOnce) if self._throws?
    fail(messages.ReturnsAndThrowsBothUsed) if self._returns?



class ExpectationList

  constructor: ->
    @_list = []

  create_expectation: ->
    expectation = new Expectation()
    @_list.push(expectation)
    expectation

  # returns undefined if not found
  find_expectation: (args...) ->
    return expectation for expectation in @_list when expectation.matches(args...)

  check_for_duplicate_expectations: (method_name) ->      # method_name is for error messages;  TODO: is there a better way?
    # TODO: use each with index and slice to avoid last element
    return if @_list.length < 2
    for outer in [0..@_list.length-2]                     # given @_list = [ a, b, c ], these
      for inner in [outer+1..@_list.length-1]             # loops produce the pairs (a,b), (a,c), (b,c)
        if @_list[outer].equals( @_list[inner] )
          fail(messages.DuplicateExpectation, method_name, @_list[outer]._args)

  # returns [ "an error re method1()", "another error re method1()", ... ]
  find_errors: (method_name) ->                           # method_name is for error messages; TODO: is there a better way?
    format(messages.ExpectationNeverCalled, method_name, expectation._args) for expectation in @_list when ! expectation._called



class MockMethodList

  constructor: ->
    @_list = []

  add: (mock_method) ->
    @_list.push(mock_method)

  # returns [ "an error re method1()", "another error re method1()", "an error re method2()", ... ]
  find_errors: ->
    @_list.reduce ( (errors, mock_method) -> errors.concat(mock_method.find_errors()) ), []

  restore_original_methods: ->
    mock_method.restore_original_method() for mock_method in @_list



#
# common functions
#

has_property = (object, property_name) ->
  object[ property_name ]? and (typeof object[ property_name ]) isnt 'function'

has_method = (object, method_name) ->
  object[ method_name ]?

is_function = (object) ->
  typeof object == 'function'

is_mock_object = (object) ->
  object.constructor.name == 'MockObject'

fail = (message, args...) ->
  throw new Error(format(message, args...))

#
# format("{0} + {1} = {2}", 2, 2, "four") => "2 + 2 = four"
#
# See: http://stackoverflow.com/questions/9880578/coffeescript-version-of-string-format-sprintf-etc-for-javascript-or-node-js
#
format = (message, args...) ->
  message.replace /{(\d)+}/g, (match, i) ->
    if typeof args[i] isnt 'undefined' then args[i] else match
    
#
# [ [], [ "a" ], [ "b", "c" ] ]   => [ "a", "b", "c" ]
# [ [], [], [] ]                  => []
#
# Don't care about this scenario:
# [ [ [ "a" ] ], [ "b"] ]         => [ [ "a" ], "b" ]
#
# See: http://stackoverflow.com/a/10865042
#
flatten = (array) ->
  [].concat.apply([], array)


#
# Export the mock() function.  In a node app:
#
#   mock = require("TinyMock")
#
# and in a browser:
#
#   <script src="TinyMock.js"></script>
#   <script>
#     mock( function(m) {
#       m.expects ...
#     });
#   </script>
#
# See: http://www.matteoagosti.com/blog/2013/02/24/writing-javascript-modules-for-both-browser-and-node/
#
if module?.exports?
  module.exports = mock
else
  window.mock = mock
