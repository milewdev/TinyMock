chai   = require("chai")
should = chai.should()
mock   = require("../src/TinyMockJS").mock


describe "test pre-conditions", ->

  it "Object does not have the property or method 'expects'", ->
    should.not.exist(Object.prototype.expects)
    
  it "instances of Object do not have the property or method 'my_method'", ->
    m = new Object()
    should.not.exist(m.my_method)
    
  it "Object does not have the property or method 'my_method'", ->
    should.not.exist(Object.prototype.my_method)
    
  it "mock() passes in objects that do not have the property or method 'my_method'", ->
    mock (m) ->
      should.not.exist(m.my_method)
  
  
describe "expects(method_name)", ->
  
  it "adds method_name to instances that do not already have a method method_name", ->
    m = new Object()
    mock ->
      m.expects("my_method")
      (typeof m.my_method).should.equal('function')
      m.my_method()                 # otherwise we'll get a 'my_method not called' error
      
  it "adds method_name to instances that already have a method method_name", ->
    m = new Object()
    m.my_method = -> "existing method"
    mock ->
      m.expects("my_method").returns("mocked method")
      m.my_method().should.equal("mocked method")
    
  it "throws an error if method_name is already a property on an instance", ->
    m = new Object()
    m.my_method = "a property"
    (->
      mock ->
        m.expects("my_method")
    ).should.throw("'my_method' is an existing property; you can only mock functions")
  
  # TODO: expects() should throw an error, stubs() should not?
  it "throws an error if method_name does not already exist in a class", ->
    class Klass
      # empty
    (->
      mock ->
        Klass.expects("my_method")
    ).should.throw("'my_method' is not an existing method; you can only mock existing methods")
      
  it "adds method_name to class prototypes that already have a method method_name", ->
    class Klass
      my_method: -> "existing method"
    mock ->
      Klass.expects("my_method").returns("mocked method")
      (new Klass()).my_method().should.equal("mocked method")
  
  it "throws an error if method_name is already a property on a class", ->
    try
      Object.prototype.my_method = "a property"
      (->
        mock ->
          Object.expects("my_method")
      ).should.throw("'my_method' is an existing property; you can only mock functions")
    finally
      delete Object.prototype.my_method
    
  it "can be called many times to expect different methods", ->
    mock (m) ->
      m.expects("my_method1")
      m.expects("my_method2")
      m.my_method1()                # otherwise we'll get a 'my_method1 not called' error
      m.my_method2()                # -- ditto --

  it "can be called after expected methods have been called (harmless but likely bad form)", ->
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

  it "throws an error if method_name is reserved", ->
    for reserved in [ "expects", "args", "returns", "check" ]
      (->
        mock (m) ->
          m.expects("#{reserved}")
      ).should.throw("you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name")


describe "args(value [, value ... ])", ->
  
  it "throws an error if no 'value' arguments are specified", ->
    (->
      mock (m) ->
        m.expects("my_method").args()
    ).should.throw("you need to supply at least one argument to args(), e.g. my_mock.expects('my_method').args(42)")
    
  it "throws an error if args() has already been called on the expectation", ->
    (->
      mock (m) ->
        m.expects("my_method").args(1,2,3).args("a","b","c")
    ).should.throw("you called args() more than once, e.g. my_mock.expects('my_method').args(1).args(2); call it just once")

  it "wraps strings with quotes in expection messages"
  
  
describe "returns(value)", ->

  it "throws an error if no 'value' argument is specified", ->
    (->
      mock (m) ->
        m.expects("my_method").returns()
    ).should.throw("you need to supply an argument to returns(), e.g. my_mock.expects('my_method').returns(123)")
    
  it "throws an error if returns() has already been called on the expectation", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).returns("abc")
    ).should.throw("you called returns() more than once, e.g. my_mock.expects('my_method').returns(1).returns(2); call it just once")

  it "throws an error if a throws error has been previously set", ->
    (->
      mock (m) ->
        m.expects("my_method").throws(new Error("an error")).returns(42)
    ).should.throw("you called returns() and throws() on the same expectation; use one or the other but not both")
    
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
    
  it "throws an error if throws() has already been called on the expectation", ->
    (->
      mock (m) ->
        m.expects("my_method").throws("an error").throws("another error")
    ).should.throw("you called throws() more than once, e.g. my_mock.expects('my_method').throws('something').throws('something else'); call it just once")

  it "throws an error if a return value has been previously set", ->
    (->
      mock (m) ->
        m.expects("my_method").returns(42).throws(new Error("an error"))
    ).should.throw("you called returns() and throws() on the same expectation; use one or the other but not both")

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


describe "mock( function( mock1 [, mock2 ...] ) )", ->
  
  it "Adds expects() to Object so that it is available on all objects", ->
    mock ->
      should.exist(Object.prototype.expects)
      
  it "Removes expects() from Object after running the passed function", ->
    mock ->
      # empty
    should.not.exist(Object.prototype.expects)
    
  it "Removes expects() from Object when the passed function throws an exception", ->
    try
      mock ->
        throw new Error("an error")
    catch error
      # ignore
    should.not.exist(Object.prototype.expects)
    
  it "does not eat exceptions thrown by the passed function", ->
    (->
      mock ->
        throw new Error("an error")
    ).should.throw("an error")
    
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
    
  it "passes pre-created convenience objects to the function argument", ->
    mock (m1, m2) ->
      m1.should.respondTo "expects"
      m2.should.respondTo "expects"

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
    m = new Object()
    m.my_method = original_method
    mock ->
      m.expects("my_method")
      m.my_method()                   # otherwise we'll get a 'my_method not called' error
    m.my_method.should.equal(original_method)
  
  it "removes the mock method on instances that did not have an original method", ->
    m = new Object()
    mock ->
      m.expects("my_method")
      m.my_method()                   # otherwise we'll get a 'my_method not called' error
    should.not.exist(m.my_method)
