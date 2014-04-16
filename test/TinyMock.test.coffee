chai      = require("chai")
should    = chai.should()
mock      = require("../src/TinyMock")
messages  = require("../messages/messages.en.json")


describe "assumptions", ->

  describe "class Object", ->

    it "does not have the property or method 'expects'", ->
      should.not.exist(Object.expects)
      should.not.exist(Object.prototype.expects)

    it "does not have the property or method 'my_expects'", ->
      should.not.exist(Object.my_expects)
      should.not.exist(Object.prototype.my_expects)

    it "does not have the property or method 'my_method'", ->
      should.not.exist(Object.my_method)
      should.not.exist(Object.prototype.my_method)

  describe "instance of Object", ->

    it "does not have the property or method 'my_method'", ->
      o = new Object()
      o.should.not.respondTo("my_method")

  describe "mock()", ->

    it.skip "passes in objects that do not have the property or method 'my_method'", ->
      mock (m) ->
        m.should.not.respondTo("my_method")


describe "general behaviour", ->

  describe "class methods", ->
    
    it "allows different expectations of the same class method on a class", ->
      class Klass
        @class_method: -> "class method"
      mock ->
        Klass.expects("class_method").args(1).returns("one")
        Klass.expects("class_method").args(2).returns("two")
        Klass.class_method(1).should.equal("one")             # forces a check for duplicate expectations
        Klass.class_method(2).should.equal("two")             # otherwise we'll get a 'class_method not called' error

    it "allows the same expectation of the same class method on different classes", ->
      class Klass1
        @class_method: -> "class method 1"
      class Klass2
        @class_method: -> "class method 2"
      mock ->
        Klass1.expects("class_method").args(1).returns("one")
        Klass2.expects("class_method").args(1).returns("one")
        Klass1.class_method(1).should.equal("one")            # forces a check for duplicate expectations
        Klass2.class_method(1).should.equal("one")            # otherwise we'll get a 'class_method not called' error

    it "allows different expectations of the same class method on different classes", ->
      class Klass1
        @class_method: -> "class method 1"
      class Klass2
        @class_method: -> "class method 2"
      mock ->
        Klass1.expects("class_method").args(1).returns("one")
        Klass2.expects("class_method").args(2).returns("two")
        Klass1.class_method(1).should.equal("one")            # forces a check for duplicate expectations
        Klass2.class_method(2).should.equal("two")            # otherwise we'll get a 'class_method not called' error

    it "allows different expectations of different class methods on different classes", ->
      class Klass1
        @class_method1: -> "class method 1"
      class Klass2
        @class_method2: -> "class method 2"
      mock ->
        Klass1.expects("class_method1").args(1).returns("one")
        Klass2.expects("class_method2").args(2).returns("two")
        Klass1.class_method1(1).should.equal("one")           # forces a check for duplicate expectations
        Klass2.class_method2(2).should.equal("two")           # otherwise we'll get a 'class_method not called' error

  describe "instance methods", ->
    
    it "allows different expectations of the same instance method on an class", ->
      class Klass
        instance_method: -> "instance method"
      k = new Klass()
      mock ->
        Klass.prototype.expects("instance_method").args(1).returns("one")
        Klass.prototype.expects("instance_method").args(2).returns("two")
        k.instance_method(1).should.equal("one")              # forces a check for duplicate expectations
        k.instance_method(2).should.equal("two")              # otherwise we'll get a 'class_method not called' error
        
    it "throws an error if an expectation of an instance method on a class does not exist", ->
      class Klass
        instance_method: -> "instance method"
      k = new Klass()
      mock ->
        Klass.prototype.expects("instance_method").args(1)
        (-> k.instance_method(2) ).should.throw(format(messages.UnknownExpectation, "instance_method", "2"))

    it "allows the same expectation of the same method on different classes", ->
      class Klass1
        instance_method: -> "instance method 1"
      class Klass2
        instance_method: -> "instance method 2"
      k1 = new Klass1()
      k2 = new Klass2()
      mock ->
        Klass1.prototype.expects("instance_method").args(1).returns("one")
        Klass2.prototype.expects("instance_method").args(1).returns("one")
        k1.instance_method(1).should.equal("one")             # forces a check for duplicate expectations
        k2.instance_method(1).should.equal("one")             # otherwise we'll get an 'instance_method not called' error

    it "allows different expectations of the same method on different classes", ->
      class Klass1
        instance_method: -> "instance method 1"
      class Klass2
        instance_method: -> "instance method 2"
      k1 = new Klass1()
      k2 = new Klass2()
      mock ->
        Klass1.prototype.expects("instance_method").args(1).returns("one")
        Klass2.prototype.expects("instance_method").args(2).returns("two")
        k1.instance_method(1).should.equal("one")             # forces a check for duplicate expectations
        k2.instance_method(2).should.equal("two")             # otherwise we'll get an 'instance_method not called' error

    it "allows different expectations of different methods on different classes", ->
      class Klass1
        instance_method1: -> "instance method 1"
      class Klass2
        instance_method2: -> "instance method 2"
      k1 = new Klass1()
      k2 = new Klass2()
      mock ->
        Klass1.prototype.expects("instance_method1").args(1).returns("one")
        Klass2.prototype.expects("instance_method2").args(2).returns("two")
        k1.instance_method1(1).should.equal("one")            # forces a check for duplicate expectations
        k2.instance_method2(2).should.equal("two")            # otherwise we'll get an 'instance_method not called' error

  describe "object methods", ->
    
    it "allows different expectations of the same object method on an object", ->
      mock (m) ->
        m.expects("object_method").args(1).returns("one")
        m.expects("object_method").args("two").returns(2)
        m.object_method(1).should.equal("one")                # forces a check for duplicate expectations
        m.object_method("two").should.equal(2)                # otherwise we'll get a 'object_method not called' error

    it "allows the same expectation of the same object method on different objects", ->
      mock (m1, m2) ->
        m1.expects("object_method").args(1).returns("one")
        m2.expects("object_method").args(1).returns("one")
        m1.object_method(1).should.equal("one")               # forces a check for duplicate expectations
        m2.object_method(1).should.equal("one")               # otherwise we'll get a 'object_method not called' error

    it "allows the different expectations of the same object method on different objects", ->
      mock (m1, m2) ->
        m1.expects("object_method").args(1).returns("one")
        m2.expects("object_method").args(2).returns("two")
        m1.object_method(1).should.equal("one")               # forces a check for duplicate expectations
        m2.object_method(2).should.equal("two")               # otherwise we'll get a 'object_method not called' error

    it "allows the different expectations of different object methods on different objects", ->
      mock (m1, m2) ->
        m1.expects("object_method1").args(1).returns("one")
        m2.expects("object_method2").args(2).returns("two")
        m1.object_method1(1).should.equal("one")              # forces a check for duplicate expectations
        m2.object_method2(2).should.equal("two")              # otherwise we'll get a 'object_method not called' error


describe "mock( [ options ], ( [ mock_object, ... ] ) -> )", ->

  it "adds an expects() method to Object.prototype", ->
    mock ->
      should.exist(Object.prototype.expects)
    # TODO: test that expects() gets removed

  it "passes five mock objects to the callback test function", ->
    mock (mocks...) ->
      mocks.length.should.equal(5)


describe "expects( method_name )", ->

  it "can mock a class method", ->
    class Klass
      @class_method: -> "class method"
    mock ->
      Klass.expects("class_method").returns("mock method")
      Klass.class_method().should.equal("mock method")
    # TODO: test that the original method is restored

  it "can mock an instance method", ->
    class Klass
      instance_method: -> "instance method"
    mock ->
      Klass.prototype.expects("instance_method").returns("mock method")
      (new Klass()).instance_method().should.equal("mock method")
    # TODO: test that the original method is restored

  it "can mock an object method", ->
    o = { object_method: -> "object method" }
    mock ->
      o.expects("object_method").returns("mock method")
      o.object_method().should.equal("mock method")
    # TODO: test that the original method is restored

  it "throws an error if called on an object that does not inherit from Object", ->
    o = Object.create(null)
    o.my_method = -> "my method"
    (->
      mock ->
        o.expects("my_method")
    ).should.throw("Object object has no method 'expects'")

  it "adds method_name to mock object instances passed in by mock()", ->
    mock (m) ->
      m.expects("my_method")
      (typeof m.my_method).should.equal('function')
      m.my_method()                 # otherwise we'll get a 'my_method not called' error

  it "mocks method_name on instances of classes that were not passed in by mock()", ->
    existing_method = -> "existing method"
    class Klass
      my_method: existing_method
    k = new Klass()
    mock ->
      k.expects("my_method")
      k.my_method.should.not.equal(existing_method)
      k.my_method()                 # otherwise we'll get a 'my_method not called' error

  it "mocks method_name on instances that were not passed in by mock()", ->
    existing_method = -> "existing method"
    o = new Object()
    o.my_method = existing_method
    mock ->
      o.expects("my_method")
      o.my_method.should.not.equal(existing_method)
      o.my_method()                 # otherwise we'll get a 'my_method not called' error

  it "throws an error if method_name does not already exist on an instance of a class that was not passed in by mock()", ->
    class Klass
      some_method: -> "some method"
    k = new Klass()
    (->
      mock ->
        k.expects("my_method")
    ).should.throw(format(messages.NotAnExistingMethod, "my_method"))

  it "throws an error if method_name does not already exist on an instance that was not passed in by mock()", ->
    o = new Object()
    o.some_method = "some method"
    (->
      mock ->
        o.expects("my_method")
    ).should.throw(format(messages.NotAnExistingMethod, "my_method"))

  # TODO: expects() should throw an error, stubs() should not?
  it "throws an error if method_name does not already exist on a class", ->
    class Klass
      # empty
    (->
      mock ->
        Klass.expects("my_method")
    ).should.throw(format(messages.NotAnExistingMethod, "my_method"))

  it "throws an error if method_name is already a property on an instance", ->
    o = new Object()
    o.my_method = "a property"
    (->
      mock ->
        o.expects("my_method")
    ).should.throw(format(messages.PreExistingProperty, "my_method"))

  it "throws an error if method_name is already a property on a class", ->
    try
      Object.prototype.my_method = "a property"
      (->
        mock ->
          Object.expects("my_method")
      ).should.throw(format(messages.PreExistingProperty, "my_method"))
    finally
      delete Object.prototype.my_method

  it "can be used many times to expect different methods", ->
    mock (m) ->
      m.expects("my_method1")
      m.expects("my_method2")
      m.my_method1()                # otherwise we'll get a 'my_method1 not called' error
      m.my_method2()                # -- ditto --

  it "can be used after expected methods have been used (harmless but bad form)", ->
    mock (m) ->
      m.expects("my_method1")
      m.my_method1()
      m.expects("my_method2")
      m.my_method2()                # otherwise we'll get a 'my_method2 not called' error

  it "throws an error if method_name is missing", ->
    (->
      mock (m) ->
        m.expects()
    ).should.throw(format(messages.ExpectsUsage, "my_method"))
    
  it "throws an error if more than one argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method1", "my_method2")
    ).should.throw(format(messages.ExpectsUsage))

  it "throws an error if method_name is the reserved name 'expects'", ->
    (->
      mock (m) ->
        m.expects("expects")
    ).should.throw(format(messages.ReservedMethodName, "expects"))

  it.skip "throws an error if method_name is the alternate name for 'expects' that is specified to mocks()", ->
    (->
      mock expects_method_name: "my_expects", (m) ->
        m.my_expects("my_expects")
    ).should.throw(format(messages.ReservedMethodName, "my_expects"))


describe "args( arg [, arg ... ] )", ->

  it "returns itself", ->
    mock (m) ->
      expectation = m.expects("my_method")
      expectation.args(1).should.equal(expectation)

  it "throws an error if no arguments are specified", ->
    (->
      mock (m) ->
        m.expects("my_method").args()
    ).should.throw(format(messages.ArgsUsage))

  it "throws an error if args() has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3).args("a","b","c")
    ).should.throw(format(messages.ArgsUsedMoreThanOnce))

  it "throws an error if called after returns()", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).args(1,2,3)
    ).should.throw(format(messages.ArgsUsedAfterReturnsOrThrows))

  it "throws an error if called after throws()", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("an error")).args(1,2,3)
    ).should.throw(format(messages.ArgsUsedAfterReturnsOrThrows))

  it "wraps strings with quotes in expection messages"


describe "returns( value )", ->

  it "causes the mock method to return the specified value", ->
    mock (m) ->
      m.expects("my_method").returns("return value")
      m.my_method().should.equal("return value")

  it "returns itself", ->
    mock (m) ->
      expectation = m.expects("my_method")
      expectation.returns(1).should.equal(expectation)

  it "throws an error if no 'value' argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns()
    ).should.throw(format(messages.ReturnsUsage))
    
  it "throws an error if more than one argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(1, 2)
    ).should.throw(format(messages.ReturnsUsage))

  it "throws an error if returns() has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).returns("abc")
    ).should.throw(format(messages.ReturnsUsedMoreThanOnce))

  it "throws an error if a throws error has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("an error")).returns(42)
    ).should.throw(format(messages.ReturnsAndThrowsBothUsed))

  it "can be called after args()", ->
    mock (m) ->
      m.expects("my_method").args(1,2,3).returns(42)
      m.my_method(1,2,3)

  it.skip "cannot be called more than once on the same expectation", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(1)
        m.expects("my_method").returns(2)
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))
      
      
describe "throws( error )", ->
  
  it "causes the mock method to throw the specified error", ->
    mock (m) ->
      m.expects("my_method").throws(new Error("an error"))
      (-> m.my_method() ).should.throw("an error")
  
  it "returns itself", ->
    mock (m) ->
      expectation = m.expects("my_method")
      expectation.throws(new Error("an error")).should.equal(expectation)

  it "throws an error if no 'error' argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws()
    ).should.throw(format(messages.ThrowsUsage))
    
  it "throws an error if more than one argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("error 1"), new Error("error 2"))
    ).should.throw(format(messages.ThrowsUsage))

  it "throws an error if throws() has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error").throws("another error")
    ).should.throw(format(messages.ThrowsUsedMoreThanOnce))

  it "throws an error if a return value has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).throws(new Error("an error"))
    ).should.throw(format(messages.ReturnsAndThrowsBothUsed))

  it "does not throw an error if a return value has been previously set on the same method with a different expectation", ->
    mock (m) ->
      m.expects("my_method").args(1,2,3).returns(42)
      m.expects("my_method").args(4,5,6).throws(new Error("an error"))
      m.my_method(1,2,3)
      (-> m.my_method(4,5,6) ).should.throw("an error")

  it "can be called after args()", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3).throws(new Error("an error"))
        m.my_method(1,2,3)
    ).should.throw("an error")

  it.skip "cannot be called more than once on the same expectation", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("error1"))
        m.expects("my_method").throws(new Error("error1"))
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))


describe "my_method( [ arg ... ] )", ->
  
  it "does not throw an error if a method is called without arguments and none were expected", ->
    mock (m) ->
      m.expects("my_method")
      m.my_method()
  
  it "does not throw an error if a method is called with arguments that were expected", ->
    mock (m) ->
      m.expects("my_method").args(1,2,3)
      m.my_method(1,2,3)
  
  it "throws an error if an unexpected method is called", ->
    (->
      mock (m) ->
        m.my_method()
    ).should.throw("has no method 'my_method'")
  
  it "throws an error if a method is called without arguments but some were expected", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3)
        m.my_method()
    ).should.throw(format(messages.UnknownExpectation, "my_method", ""))
  
  it "throws an error if a method is called with argments but none were expected", ->
    (->
      mock (m) ->
        m.expects("my_method")
        m.my_method(1,2,3)
    ).should.throw(format(messages.UnknownExpectation, "my_method", "1,2,3"))
  
  it "throws an error if a method is called with arguments but different arguments were expected", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3)
        m.my_method(4,5,6)
    ).should.throw(format(messages.UnknownExpectation, "my_method", "4,5,6"))

  it "returns the value specified in a returns()", ->
    mock (m) ->
      m.expects("my_method").returns(123)
      m.my_method().should.equal(123)

  it "returns undefined if no returns() was specified", ->
    mock (m) ->
      m.expects("my_method")
      should.not.exist(m.my_method())

  it "throws the error specified in a throws()", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error")
        m.my_method()
    ).should.throw("an error")

  it "allows a method with args and the same method without args", ->
    mock (m) ->
      m.expects("my_method").args(1,2,3)
      m.expects("my_method")
      m.my_method(1,2,3)
      m.my_method()

  it "throws an error if an expectation with no args is duplicated", ->
    (->
      mock (m) ->
        m.expects("my_method")
        m.expects("my_method")
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))

  it "throws an error if an expectation with args is duplicated", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3)
        m.expects("my_method").args(1,2,3)
        m.my_method(1,2,3)
    ).should.throw(format(messages.DuplicateExpectation, "my_method", "1,2,3"))

  it "throws an error when the same method returns the same values", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(1)
        m.expects("my_method").returns(1)
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))

  it "throws an error when the same method returns different values", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(1)
        m.expects("my_method").returns(2)
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))

  it "throws an error when the same method throws the same values", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error")
        m.expects("my_method").throws("an error")
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))

  it "throws an error when the same method throws different values", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error")
        m.expects("my_method").throws("another error")
        m.my_method()
    ).should.throw(format(messages.DuplicateExpectation, "my_method", ""))


# This is a duplicate of a function in TinyMock.coffee, but this
# application is currently so small that it is not worth worrying
# about it.
format = (message, args...) ->    # format("{0} + {1} = {2}", 2, 2, "four") => "2 + 2 = four"
  message.replace /{(\d)+}/g, (match, i) ->
    if typeof args[i] isnt 'undefined' then args[i] else match




###
describe "mock( function( mock1 [, mock2 ...] ) )", ->

  it "throws an error if there are no arguments", ->
    (->
      mock()  # need parenthesis to coerce function call
    ).should.throw(messages.MockUsage)

  it "throws an error if there are more than two arguments", ->
    (->
      mock 1, 2, 3
    ).should.throw(messages.MockUsage)

  it "throws an error if there is one argument and it is not a function", ->
    (->
      mock 1
    ).should.throw(messages.MockUsage)

  it "throws an error if there are two arguments and the first one is not an object", ->
    (->
      mock "expects", -> 0
    ).should.throw(messages.MockUsage)

  it "throws an error if there are two arguments and the second one is not a function", ->
    (->
      mock expects_method_name: "expects", 1
    ).should.throw(messages.MockUsage)

  it "throws an error if the options arguments has neither the expects_method_name nor the mock_count properties", ->
    (->
      mock a: "expects", b: 3, -> 0
    ).should.throw(messages.MockBadUsage)

  it "adds expects() to Object so that it is available on all objects", ->
    mock ->
      Object.should.respondTo("expects")

  it "adds the expects method name that was passed as an option to mock()", ->
    mock expects_method_name: "my_expects", ->
      Object.should.respondTo("my_expects")

  it "removes expects() from Object after running the passed function", ->
    mock ->
      # empty
    Object.should.not.respondTo("expects")

  it "removes the expects method name that was passed as an option to mock()", ->
    mock expects_method_name: "my_expects", ->
      # empty
    Object.should.not.respondTo("my_expects")

  it "removes expects() from Object when the passed function throws an error", ->
    try
      mock ->
        throw new Error("an error")
    catch error
      # ignore
    Object.should.not.respondTo("expects")

  it "removes the expects method name that was passed as an option to mock() when the passed function throws an error", ->
    try
      mock expects_method_name: "my_expects", ->
        throw new Error("an error")
    catch error
      # ignore
    Object.should.not.respondTo("my_expects")

  it "throws an error if expects() is already a method of Object", ->
    try
      Object.prototype.expects = -> "existing expects method"
      (->
        mock ->
          # empty
      ).should.throw(format(messages.ExpectsMethodAlreadyExists, "expects"))
    finally
      delete Object.prototype.expects

  it "throws an error if the expects method name that was passed as an option to mock() is already a method of Object", ->
    try
      Object.prototype.my_expects = -> "existing my_expects method"
      (->
        mock expects_method_name: "my_expects", ->
          # empty
      ).should.throw(format(messages.ExpectsMethodAlreadyExists, "my_expects"))
    finally
      delete Object.prototype.my_expects

  it "does not eat errors thrown by the passed function", ->
    (->
      mock ->
        throw new Error("an error")
    ).should.throw("an error")

  it "passes pre-created convenience Mock objects to the function argument", ->
    mock (m) ->
      m.constructor.name.should.equal("MockObject")

  it "passes 5 mock objects to the function argument", ->
    mock (m...) ->
      m.length.should.equal(5)

  it "passes mock_count mock objects to the function argument when the mock_count option is used", ->
    mock mock_count: 17, (m...) ->
      m.length.should.equal(17)

  it "checks expectations for errors if the passed function did not throw an error", ->
    (->
      mock (m) ->
        m.expects("my_method")
    ).should.throw(format(messages.ExpectationNeverCalled, "my_method", ""))

  it "does not check expectations for errors if the passed function throws an error", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("an error"))
        m.my_method()
    ).should.throw(/^an error$/)

  it "reports all unmet expectations", ->
    (->
      mock (m1, m2) ->
        m1.expects("my_method1").args(1,2,3)
        m2.expects("my_method2")
    ).should.throw("#{format(messages.ExpectationNeverCalled, 'my_method1', '1,2,3')}\n#{format(messages.ExpectationNeverCalled, 'my_method2', '')}\n")

  it "restores the original method on class prototypes", ->
    original_method = -> "anything"
    class Klass
      my_method: original_method
    mock ->
      Klass.expects("my_method")
      (new Klass()).my_method()       # otherwise we'll get a 'my_method not called' error
    Klass.prototype.my_method.should.equal(original_method)

  it "restores the original method on instances that had the original method", ->
    original_method = -> "anything"
    o = new Object()
    o.my_method = original_method
    mock ->
      o.expects("my_method")
      o.my_method()                   # otherwise we'll get a 'my_method not called' error
    o.my_method.should.equal(original_method)

  it "restores the orginal method when the same method has more than one expectation", ->
    original_method = -> "anything"
    o = new Object()
    o.my_method = original_method
    mock ->
      o.expects("my_method").args(1)
      o.expects("my_method").args(2)
      o.my_method(1)                  # otherwise we'll get a 'my_method not called' error
      o.my_method(2)
    o.my_method.should.equal(original_method)

  it "cannot be nested without specifying expects_method_name (no reason to do this but we'll test it anyway)", ->
    (->
      mock (m1) ->
        mock (m2) ->
          # empty
    ).should.throw(format(messages.ExpectsMethodAlreadyExists, "expects"))

  it "can be nested if expects_method_name is specified (no reason to do this but we'll test it anyway)", ->
    mock (m0) ->
      mock expects_method_name: "my_expects1", (m1) ->
        mock expects_method_name: "my_expects2", (m2) ->
          m0.expects("my_method0")
          m1.my_expects1("my_method1")
          m2.my_expects2("my_method2")
          m0.my_method0()
          m1.my_method1()
          m2.my_method2()

  it "allows one mock object to use another", ->
    mock (m1, m2) ->
      m1.expects("my_method").returns(m2)
      m1.my_method().should.equal(m2)

  it "allows a different expectation method name to be used instead of 'expects'", ->
    class Klass
      expects: -> "pre-existing expects() method"
    k = new Klass()
    mock expects_method_name: "my_expects", ->
      k.my_expects("expects").returns("overridden expects() method")
      k.expects().should.equal("overridden expects() method")
###
