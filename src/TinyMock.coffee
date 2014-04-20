messages = require("../messages/messages.en.json")


#
# The mock() function sets up a mocking environment or scope where 
# a test function can set method call expectations on objects.  It 
# then runs the test function, checks that all expectations were 
# met, and finally cleans up the environment:
#
#   fs = require("fs")                                  # a dependency
#   sut = new Sut()                                     # something under test
#   mock ->                                             # start mocking scope: add expects() to Object.prototype
#     fs.expects("writeFileSync").args("some content")  # set an expectation: replace writeFileSync with a mock version
#     sut.do_something_interesting()                    # do whatever it is we want to test
#   ...                                                 # end scope: check expectations, remove expects(), restore original writeFileSync()
#
class MockFunction

  @mock: (args...) ->
    mock = new MockFunction()
    mock.load_args(args)
    mock.setup_environment()
    try
      mock.run_test_function()
      mock.verify_expectations()
    finally
      mock.cleanup_environment()

  constructor: ->
    @_test_function = undefined
    @_expects_method_name = undefined
    @_mock_count = undefined
    @_mock_objects = undefined
    @_mock_methods = undefined
    
  load_args: (args) ->
    @check_usage(args)
    @parse_args(args)
    @check_expects_method_name()

  setup_environment: (args) ->
    @create_mock_objects()
    @create_empty_mock_methods_list()
    @install_expects_method()

  run_test_function: ->
    @_test_function.apply(null, @_mock_objects)

  verify_expectations: ->
    errors = @_mock_methods.find_errors()
    fail( errors.join("\n") + "\n" ) if errors.length > 0

  cleanup_environment: ->
    @_mock_methods.restore_original_methods()
    @uninstall_expects_method()

  check_usage: (args) ->
    switch args.length
      when 1
        fail(messages.MockUsage) unless is_function(args[0])
      when 2
        fail(messages.MockBadUsage) unless has_property(args[0], "expects_method_name") or has_property(args[0], "mock_count")
        fail(messages.MockUsage) unless is_function(args[1])
      else
        fail(messages.MockUsage)

  parse_args: (args) ->
    switch args.length
      when 1
        @_test_function = args[0]
      when 2
        @_expects_method_name = args[0].expects_method_name
        @_mock_count = args[0].mock_count
        @_test_function = args[1]
    @_expects_method_name ?= "expects"
    @_mock_count ?= 5
    # TODO: what happens if expects_method_name is not a legal method name?
    # TODO: what happens if mock_count is not a number?

  check_expects_method_name: ->
    fail(messages.ExpectsMethodAlreadyExists, @_expects_method_name) if Object.prototype[@_expects_method_name]?

  install_expects_method: ->
    Object.prototype[@_expects_method_name] = new_ExpectsMethod(@_expects_method_name, @_mock_methods)

  uninstall_expects_method: ->
    delete Object.prototype[@_expects_method_name]

  create_mock_objects: ->
    @_mock_objects = ( new MockObject() for i in [1..@_mock_count] )

  create_empty_mock_methods_list: ->
    @_mock_methods = new MockMethodList()    


new_ExpectsMethod = (expects_method_name, mock_methods)->
  
  expects_method = (method_name) ->
    check_expects_usage(@, method_name, arguments.length)
    if not is_mock_method(@[method_name])
      @[method_name] = new_MockMethod(@, method_name)
      mock_methods.add(@[method_name])
    @[method_name].create_expectation()
  
  check_expects_usage = (self, method_name, arg_count) ->
    fail(messages.ExpectsUsage) unless method_name?
    fail(messages.ExpectsUsage) unless arg_count == 1
    fail(messages.NotAnExistingMethod, method_name) unless is_mock_object(self) or has_method(self, method_name)
    fail(messages.PreExistingProperty, method_name) if has_property(self, method_name)
    fail(messages.ReservedMethodName, method_name) if is_reserved_method_name(method_name)
    
  is_mock_method = (method) ->
    mock_methods.contains(method)
    
  is_reserved_method_name = (method_name) ->
    method_name == expects_method_name
  
  expects_method
    
    
new_MockMethod = (object, method_name) ->

  expectations = new ExpectationList()
  original_method = object[method_name]

  mock_method = (args...) ->
    expectations.check_for_duplicates(method_name)                              # TODO: explain why we do this here
    expectation = expectations.find(args...)
    fail(messages.UnknownExpectation, method_name, args) unless expectation
    expectation._called = yes
    throw expectation._throws if expectation._throws
    expectation._returns
    
  mock_method.create_expectation = ->
    expectation = new Expectation()
    expectations.add(expectation)
    expectation

  mock_method.restore_original_method = ->
    if original_method?
      object[method_name] = original_method
    else
      delete object[method_name]

  mock_method.find_errors = ->
    expectations.find_errors(method_name)

  mock_method
    

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
    fail(messages.ReturnsUsage) unless arg_count == 1
    fail(messages.ReturnsUsedMoreThanOnce) if self._returns?
    fail(messages.ReturnsAndThrowsBothUsed) if self._throws?

  _check_throws_usage = (self, error, arg_count) ->
    fail(messages.ThrowsUsage) unless error?
    fail(messages.ThrowsUsage) unless arg_count == 1
    fail(messages.ThrowsUsedMoreThanOnce) if self._throws?
    fail(messages.ReturnsAndThrowsBothUsed) if self._returns?


class ExpectationList

  constructor: ->
    @_list = []
    
  add: (expectation) ->
    @_list.push(expectation)

  # returns undefined if not found
  find: (args...) ->
    return expectation for expectation in @_list when expectation.matches(args...)

  check_for_duplicates: (method_name) ->                  # method_name is for error messages;  TODO: is there a better way?
    # TODO: use each with index and slice to avoid last element
    return if @_list.length < 2
    for outer in [0..@_list.length-2]                     # given @_list = [ a, b, c ], these
      for inner in [outer+1..@_list.length-1]             # loops produce the pairs (a,b), (a,c), (b,c)
        if @_list[outer].equals( @_list[inner] )
          fail(messages.DuplicateExpectation, method_name, @_list[outer]._args)

  # returns [ "an error re method1()", "another error re method1()", ... ]
  find_errors: (method_name) ->                           # method_name is for error messages; TODO: is there a better way?
    format(messages.ExpectationNeverCalled, method_name, expectation._args) for expectation in @_list when not expectation._called


class MockMethodList

  constructor: ->
    @_list = []

  add: (mock_method) ->
    @_list.push(mock_method)
    
  contains: (mock_method) ->
    @_list.indexOf(mock_method) != -1

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
  module.exports = MockFunction.mock
else
  window.mock = MockFunction.mock
