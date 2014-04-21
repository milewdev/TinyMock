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
#     fs.expects("writeFileSync").args("some content")  # set an expectation: replace writeFileSync() with a mock method
#     sut.do_something_interesting()                    # run whatever it is we want to test
#   ...                                                 # end scope: check expectations, remove expects(), restore original writeFileSync()
#
mock = (args...) ->
  
  test_function = undefined
  expects_method_name = undefined
  mock_count = undefined
  mock_objects = undefined
  mock_methods = undefined

  read_args = (args) ->
    check_usage(args)
    parse_args(args)
    check_expects_method_name()

  setup_environment = ->
    create_mock_objects()
    create_empty_mock_methods_list()
    install_expects_method()

  run_test_function = ->
    test_function.apply(null, mock_objects)

  verify_expectations = ->
    errors = mock_methods.find_errors()
    fail( errors.join("\n") + "\n" ) if errors.length > 0

  cleanup_environment = ->
    mock_methods.uninstall_mock_methods()
    uninstall_expects_method()

  check_usage = (args) ->
    switch args.length
      when 1
        fail(messages.MockUsage) unless is_function(args[0])
      when 2
        fail(messages.MockBadUsage) unless has_property(args[0], "expects_method_name") or has_property(args[0], "mock_count")
        fail(messages.MockCountNotANumber, args[0].mock_count) if args[0].mock_count? and not is_integer(args[0].mock_count)
        fail(messages.MockCountNegative, args[0].mock_count, -1 * args[0].mock_count) if args[0].mock_count? and (args[0].mock_count < 0)
        fail(messages.MockUsage) unless is_function(args[1])
      else
        fail(messages.MockUsage)

  parse_args = (args) ->
    switch args.length
      when 1
        test_function = args[0]
      when 2
        expects_method_name = args[0].expects_method_name
        mock_count = args[0].mock_count
        test_function = args[1]
    expects_method_name ?= "expects"
    mock_count ?= 5

  check_expects_method_name = ->
    fail(messages.ExpectsMethodAlreadyExists, expects_method_name) if Object.prototype[expects_method_name]?

  install_expects_method = ->
    Object.prototype[expects_method_name] = ExpectsMethod(expects_method_name, mock_methods)

  uninstall_expects_method = ->
    delete Object.prototype[expects_method_name]

  create_mock_objects = ->
    mock_objects = ( new MockObject() for i in [1..mock_count] )

  create_empty_mock_methods_list = ->
    mock_methods = new MockMethodList()    
  
  read_args(args)
  setup_environment()
  try
    run_test_function()
    verify_expectations()
  finally
    cleanup_environment()


ExpectsMethod = (expects_method_name, mock_methods)->
  
  expects_method = (method_name) ->
    check_usage(@, method_name, arguments.length)
    install_mock_method(@, method_name) unless is_mock_method(@[method_name])
    @[method_name].create_expectation()
  
  check_usage = (self, method_name, arg_count) ->
    fail(messages.ExpectsUsage) unless method_name?
    fail(messages.ExpectsUsage) unless arg_count == 1
    fail(messages.NotAnExistingMethod, method_name) unless is_mock_object(self) or has_method(self, method_name)
    fail(messages.PreExistingProperty, method_name) if has_property(self, method_name)
    fail(messages.ReservedMethodName, method_name) if is_reserved_method_name(method_name)
    
  install_mock_method = (self, method_name) ->
    mock_method = MockMethod(self, method_name)
    mock_method.install()
    mock_methods.register(mock_method)
    
  is_mock_method = (method) ->
    mock_methods.contains(method)
    
  is_reserved_method_name = (method_name) ->
    method_name == expects_method_name
  
  expects_method
    
    
MockMethod = (object, method_name) ->

  expectations = new ExpectationList()
  original_method = undefined

  mock_method = (args...) ->
    expectations.check_for_duplicates(method_name)                              # TODO: explain why we do this here
    expectation = expectations.find(args...)
    fail(messages.UnknownExpectation, method_name, args) unless expectation
    expectation._called = yes
    throw expectation._throws if expectation._throws
    expectation._returns
    
  mock_method.install = ->
    original_method = object[method_name]
    object[method_name] = mock_method

  mock_method.uninstall = ->
    if original_method?
      object[method_name] = original_method
    else
      delete object[method_name]
    
  mock_method.create_expectation = ->
    expectation = new Expectation()
    expectations.register(expectation)
    expectation

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

  # m.expects("my_method").args(1,2,"three")
  args: (args...) ->
    check_args_usage(@, args)
    @_args = args
    @

  # m.expects("my_method").returns(42)
  returns: (value) ->
    check_returns_usage(@, value, arguments.length)
    @_returns = value
    @

  # m.expects("my_method").throws(new Error("an error message"))
  throws: (error) ->
    check_throws_usage(@, error, arguments.length)
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

  check_args_usage = (self, args) ->
    fail(messages.ArgsUsage) if args.length == 0
    fail(messages.ArgsUsedMoreThanOnce) unless self._args.length == 0
    fail(messages.ArgsUsedAfterReturnsOrThrows) if self._returns? or self._throws?

  check_returns_usage = (self, value, arg_count) ->
    fail(messages.ReturnsUsage) unless value?
    fail(messages.ReturnsUsage) unless arg_count == 1
    fail(messages.ReturnsUsedMoreThanOnce) if self._returns?
    fail(messages.ReturnsAndThrowsBothUsed) if self._throws?

  check_throws_usage = (self, error, arg_count) ->
    fail(messages.ThrowsUsage) unless error?
    fail(messages.ThrowsUsage) unless arg_count == 1
    fail(messages.ThrowsUsedMoreThanOnce) if self._throws?
    fail(messages.ReturnsAndThrowsBothUsed) if self._returns?


class ExpectationList

  constructor: ->
    @_list = []
    
  register: (expectation) ->
    @_list.push(expectation)

  # returns undefined if not found
  find: (args...) ->
    return expectation for expectation in @_list when expectation.matches(args...)

  # method_name is for error messages
  check_for_duplicates: (method_name) ->        
    return if @_list.length < 2
    for outer in [0..@_list.length-2]           # given @_list = [ a, b, c ], these loops produce the pairs (a,b), (a,c), (b,c)
      for inner in [outer+1..@_list.length-1]
        if @_list[outer].equals( @_list[inner] )
          fail(messages.DuplicateExpectation, method_name, @_list[outer]._args)

  # method_name is for error messages
  # returns [ "an error re method1()", "another error re method1()", ... ]
  find_errors: (method_name) ->                 
    format(messages.ExpectationNeverCalled, method_name, expectation._args) for expectation in @_list when not expectation._called


class MockMethodList

  constructor: ->
    @_list = []

  register: (mock_method) ->
    @_list.push(mock_method)
    
  contains: (mock_method) ->
    @_list.indexOf(mock_method) != -1

  # returns [ "an error re method1()", "another error re method1()", "an error re method2()", ... ]
  find_errors: ->
    @_list.reduce ( (errors, mock_method) -> errors.concat(mock_method.find_errors()) ), []

  uninstall_mock_methods: ->
    mock_method.uninstall() for mock_method in @_list


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
  
# See: http://stackoverflow.com/a/3886106
is_integer = (number) ->
  (typeof number is 'number') && (number % 1 == 0)

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
  module.exports = mock
else
  window.mock = mock
