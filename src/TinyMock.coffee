#
# For background, please see:
#
# tutorial:  http://milewdev.github.io/TinyMock.doc/tutorial.html
# reference: http://milewdev.github.io/TinyMock.doc/reference.html
#


#
# All error messages are stored in an external json file which we load
# into 'messages'.  This is the only state that is maintained between
# calls to mock().
#
messages = require("../messages/messages.en.json")


#
# The mock() function sets up a mocking environment, or scope, where
# a test function can set method call expectations on objects.  It
# then runs the test function, checks that all expectations were
# met, and finally cleans up the environment:
#
#   fs = require("fs")                                  # a dependency
#   sut = new Sut()                                     # something under test
#   mock ->                                             # start mocking scope: adds expects() to Object.prototype
#     fs.expects("writeFileSync").args("some content")  # set an expectation: replace writeFileSync() with a mock method
#     sut.do_something_interesting()                    # run whatever it is we want to test
#                                                       # end scope: checks expectations, removes expects(), restores original writeFileSync()
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

  # main function body
  read_args(args)
  setup_environment()
  try
    run_test_function()
    verify_expectations()
  finally
    cleanup_environment()


#
# ExpectsMethod is a function closure that implements the expects() method:
#
#   mock (m) ->
#     m.expects("my_method")
#     ...
#
# Many expectations can be set on the same method:
#
#   mock (m) ->
#     m.expects("my_method").args(1, 2, 3)
#     m.expects("my_method").args(4, 5, 6)
#
# These are represented internally by one instance of MockMethod for
# "my_method", which itself has a list of two expectations, one with args 1,
# 2, and 3, and the second with args 4, 5, and 6.
#
# expects() first validates the method_name argument ("my_method" in the
# examples above).  It then installs a mock method for method_name if one has
# not already been installed, and finally it creates a new expectation, which
# it returns to the caller.  Rewriting the example above to make the process
# clearer:
#
#   mock (m) ->
#     expectation1 = m.expects("my_method")   # install mock "my_method"; create and return an expectation
#     expectation1.args(1, 2, 3)
#     expectation2 = m.expects("my_method")   # "my_method" already mocked; create and return another expectation
#     expectation2.args(4, 5, 6)
#
ExpectsMethod = (expects_method_name, mock_methods)->

  # this is the actual expects() method
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

  # main function body
  expects_method


#
# MockMethod is a function closure that implements the mock methods installed
# by expects().  A mock method has a list of one or more expectations; when
# the mock method is invoked with various arguments, it retrieves the matching
# expectation and marks it as called (i.e. the expectation was met).  Finally,
# it throws the expectation's throw error, if it has one, or it returns the
# expectation's return value.
#
# MockMethod is also resposible for checking for duplicate expectations as all
# expectations will have been specified when it is called, and it also has
# access to the list of expectations:
#
#   mock (m) ->
#     expectation1 = m.expects("my_method")
#     expectation1.args(1,2,3)
#     expectation2 = m.expects("my_method")   # cannot check for duplicates because args() not called yet, if at all
#     expectation2.args(1,2,3)                # could check in the args() method but it does not have clean access to expectation1
#     m.my_method()                           # best place to do it, as my_method mock method has the list of all expectations
#
# A MockMethod instance replaces an existing method on an object (except MockObject
# instances passed in by mock()), and that existing method is restored when mock()
# finishes.  The MockMethod instance is a convenient place to save the original
# method and so MockMethod provides install() and uninstall() methods to help
# with this.
#
# Finally, since MockMethod maintains a list of expectations, it provides a
# create_expectation() method to create a new expectation, add it to the list,
# and return it to the caller.  It also provides a find_errors() method to
# gather and return any errors from each of the expectations in the list.
#
MockMethod = (object, method_name) ->

  expectations = new ExpectationList()
  original_method = undefined

  # this is the actual mock method
  mock_method = (args...) ->
    expectations.check_for_duplicates(method_name)
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

  # main function body
  mock_method


#
# Instances of MockObject area created by mock() and passed to the test
# function.  It is an empty class that exists solely so that expects()
# can distinguish between 'regular' objects and those passed by mock():
# expectations can only be set on existing methods of regular objects,
# whereas expectations can be set on non-existing methods on MockObjects.
#
class MockObject

  # empty


#
# An Expectation represents the set of method arguments of a method
# invocation.  For example:
#
#   my_method(1, 2, 3)
#   my_method(4, 5, 6)
#
# are two expectations of the method my_method(), the first with arguments
# 1, 2, and 3, the second with 4, 5, and 6.
#
# Sometimes it is necessary for mocked methods to return values or throw
# errors in order for the system under test to function correctly,
# therefore an expectation can have a return value or a throws value,
# but not both.
#
# Finally, an expectation is met when it is called, so Expectation has
# a called flag that is set to true to note that the expectation was met.
#
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


#
# ExpectationList is simply an array of Expectations with some additional
# convenience methods.
#
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


#
# MockMethodList is simply an array of MockMethods with some additional
# convenience methods.
#
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
  object[ property_name ]? and (typeof object[ property_name ] isnt 'function')

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
