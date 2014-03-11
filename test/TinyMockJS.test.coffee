chai   = require("chai")
should = chai.should()
mock   = require("../src/TinyMockJS").mock


describe "test pre-conditions", ->

  it "Object does not have the property or method 'expects'", ->
    should.not.exist(Object.prototype.expects)
    
  it "Object does not have the property or method 'my_expects'", ->
    should.not.exist(Object.prototype.my_expects)

  it "Object does not have the property or method 'my_method'", ->
    should.not.exist(Object.prototype.my_method)

  it "instances of Object do not have the property or method 'my_method'", ->
    o = new Object()
    should.not.exist(o.my_method)

  it "mock() passes in objects that do not have the property or method 'my_method'", ->
    mock (m) ->
      should.not.exist(m.my_method)


describe "mock( function( mock1 [, mock2 ...] ) )", ->
  
  it "throws an error if there are no arguments", ->
    (->
      mock()  # need parenthesis to coerce function call
    ).should.throw("you need to pass either a function, or options and a function, to mock(), e.g. mock expects_method_name: 'exp', (m) -> m.expects('my_method') ...")

  it "throws an error if there are more than two arguments", ->
    (->
      mock 1, 2, 3
    ).should.throw("you need to pass either a function, or options and a function, to mock(), e.g. mock expects_method_name: 'exp', (m) -> m.expects('my_method') ...")

  it "throws an error if there is one argument and it is not a function", ->
    (->
      mock 1
    ).should.throw("you need to pass either a function, or options and a function, to mock(), e.g. mock expects_method_name: 'exp', (m) -> m.expects('my_method') ...")

  it "throws an error if there are two arguments and the first one is not an object", ->
    (->
      mock "expects", -> 0
    ).should.throw("you need to pass either a function, or options and a function, to mock(), e.g. mock expects_method_name: 'exp', (m) -> m.expects('my_method') ...")

  it "throws an error if there are two arguments and the second one is not a function", ->
    (->
      mock expects_method_name: "expects", 1
    ).should.throw("you need to pass either a function, or options and a function, to mock(), e.g. mock expects_method_name: 'exp', (m) -> m.expects('my_method') ...")
    
  it "throws an error if the options arguments has neither the expects_method_name nor the mock_count properties", ->
    (->
      mock a: "expects", b: 3, -> 0
    ).should.throw("the options argument should have attributes expects_method_name or mock_count; found attributes: a, b")
  
  it "Adds expects() to Object so that it is available on all objects", ->
    mock ->
      should.exist(Object.prototype.expects)
      
  it "Adds the expects method name that was passed as an option to mock()", ->
    mock expects_method_name: "my_expects", ->
      should.exist(Object.prototype.my_expects)

  it "Removes expects() from Object after running the passed function", ->
    mock ->
      # empty
    should.not.exist(Object.prototype.expects)

  it "Removes the expects method name that was passed as an option to mock()", ->
    mock expects_method_name: "my_expects", ->
      # empty
    should.not.exist(Object.prototype.my_expects)    

  it "Removes expects() from Object when the passed function throws an exception", ->
    try
      mock ->
        throw new Error("an error")
    catch error
      # ignore
    should.not.exist(Object.prototype.expects)
    
  it "Removes the expects method name that was passed as an option to mock() when the passed function throws an exception", ->
    try
      mock expects_method_name: "my_expects", ->
        throw new Error("an error")
    catch error
      # ignore
    should.not.exist(Object.prototype.my_expects)

  it "does not eat exceptions thrown by the passed function", ->
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
    ).should.throw("'my_method()' was never called")

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
    ).should.throw( "'my_method1(1,2,3)' was never called\n'my_method2()' was never called\n" )

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
    
  it "can be nested (cannot see the need, but just to verify that it will work)", ->
    mock (m1) ->
      mock (m2) ->
        m1.expects("my_method1")
        m2.expects("my_method2")
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


describe "expects(method_name)", ->
  
  it "adds method_name to mock objects passed in by mock()", ->
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
      
  it "mocks method_name on objects that were not passed in by mock()", ->
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
    ).should.throw("'my_method' is not an existing method; you can only mock existing methods on objects (or classes) not passed in by mock()")      
      
  it "throws an error if method_name does not already exist on an object that was not passed in by mock()", ->
    o = new Object()
    o.some_method = "some method"
    (->
      mock ->
        o.expects("my_method")
    ).should.throw("'my_method' is not an existing method; you can only mock existing methods on objects (or classes) not passed in by mock()")      
      
  # TODO: expects() should throw an error, stubs() should not?
  it "throws an error if method_name does not already exist on a class", ->
    class Klass
      # empty
    (->
      mock ->
        Klass.expects("my_method")
    ).should.throw("'my_method' is not an existing method; you can only mock existing methods on objects (or classes) not passed in by mock()")      

  it "throws an error if method_name is already a property on an instance", ->
    o = new Object()
    o.my_method = "a property"
    (->
      mock ->
        o.expects("my_method")
    ).should.throw("'my_method' is an existing property; you can only mock functions")

  it "throws an error if method_name is already a property on a class", ->
    try
      Object.prototype.my_method = "a property"
      (->
        mock ->
          Object.expects("my_method")
      ).should.throw("'my_method' is an existing property; you can only mock functions")
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
    ).should.throw("you need to supply a method name to expects(), e.g. my_mock.expects('my_method')")

  it "throws an error if method_name is the reserved name 'expects'", ->
    (->
      mock (m) ->
        m.expects("expects")
    ).should.throw("you cannot use my_mock.expects('expects'); 'expects' is a reserved method name")
    
  it "throws an error if method_name is the alternate name for 'expects' that is specified to mocks()", ->
    (->
      mock expects_method_name: "my_expects", (m) ->
        m.my_expects("my_expects")
    ).should.throw("you cannot use my_mock.my_expects('my_expects'); 'my_expects' is a reserved method name")


describe "args(value [, value ... ])", ->

  it "throws an error if no 'value' arguments are specified", ->
    (->
      mock (m) ->
        m.expects("my_method").args()
    ).should.throw("you need to supply at least one argument to args(), e.g. my_mock.expects('my_method').args(42)")

  it "throws an error if args() has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3).args("a","b","c")
    ).should.throw("you specified args() more than once, e.g. my_mock.expects('my_method').args(1).args(2); use it once per expectation")

  it "wraps strings with quotes in expection messages"


describe "returns(value)", ->

  it "throws an error if no 'value' argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns()
    ).should.throw("you need to supply an argument to returns(), e.g. my_mock.expects('my_method').returns(123)")

  it "throws an error if returns() has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).returns("abc")
    ).should.throw("you specified returns() more than once, e.g. my_mock.expects('my_method').returns(1).returns(2); use it once per expectation")

  it "throws an error if a throws error has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("an error")).returns(42)
    ).should.throw("you specified both returns() and throws() on the same expectation; use one or the other on an expectation")

  it "can be called after args()", ->
    mock (m) ->
      m.expects("my_method").args(1,2,3).returns(42)
      m.my_method(1,2,3)

  it "can be called before args() (but not good style)", ->
    mock (m) ->
      m.expects("my_method").returns(42).args(1,2,3)
      m.my_method(1,2,3)


describe "throws(error)", ->

  it "throws an error if no 'error' argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws()
    ).should.throw("you need to supply an argument to throws(), e.g. my_mock.expects('my_method').throws('an error')")

  it "throws an error if throws() has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error").throws("another error")
    ).should.throw("you specified throws() more than once, e.g. my_mock.expects('my_method').throws('something').throws('something else'); use it once per expectation")

  it "throws an error if a return value has already been specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).throws(new Error("an error"))
    ).should.throw("you specified both returns() and throws() on the same expectation; use one or the other on an expectation")

  it "does not throw an error if a return value has been previously set on the same method with a different signature", ->
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

  it "can be called before args() (but not good style)", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("an error")).args(1,2,3)
        m.my_method(1,2,3)
    ).should.throw("an error")


describe "my_method([ value [, value ... ] ])", ->

  it "does not throw an error if my_method is called and was expected", ->
    mock (m) ->
      m.expects("my_method")
      m.my_method()

  it "throws an error if my_method is called but was not expected", ->
    (->
      mock (m) ->
        m.my_method()
    ).should.throw("has no method 'my_method'")

  it "throws an error if my_method is called with arguments but none were expected", ->
    (->
      mock (m) ->
        m.expects("my_method")
        m.my_method(1,2,3)
    ).should.throw("my_method(1,2,3) does not match any expectations")

  it "throws an error if the args do not match any expectations", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3)
        m.my_method(4,5,6)
    ).should.throw("my_method(4,5,6) does not match any expectations")

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

  it "throws an error if a method requires args but is called with none", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3)
        m.my_method()
    ).should.throw("my_method() does not match any expectations")

  it "throws an error if a method signature with no args is duplicated", ->
    (->
      mock (m) ->
        m.expects("my_method")
        m.expects("my_method")
        m.my_method()
    ).should.throw("my_method() is a duplicate expectation")

  it "throws an error if a method signature with args is duplicated", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3)
        m.expects("my_method").args(1,2,3)
        m.my_method(1,2,3)
    ).should.throw("my_method(1,2,3) is a duplicate expectation")

  it "throws an exception when the same method returns the same values", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(1)
        m.expects("my_method").returns(1)
        m.my_method()
    ).should.throw("my_method() is a duplicate expectation")

  it "throws an exception when the same method returns different values", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(1)
        m.expects("my_method").returns(2)
        m.my_method()
    ).should.throw("my_method() is a duplicate expectation")

  it "throws an exception when the same method throws the same values", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error")
        m.expects("my_method").throws("an error")
        m.my_method()
    ).should.throw("my_method() is a duplicate expectation")

  it "throws an exception when the same method throws different values", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error")
        m.expects("my_method").throws("another error")
        m.my_method()
    ).should.throw("my_method() is a duplicate expectation")
