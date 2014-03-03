{mock, Mock, Expectation} = require("../src/TinyMockJS")


describe "Expectation.args( value [, value ... ] )", ->
  
  it "returns the Expectation instance", ->
    exp = new Expectation("my_method")
    exp.args(42).should.equal(exp)
    
  it "throws an error if no 'value' arguments are specified", ->
    exp = new Expectation("my_method")
    (-> exp.args() ).should.throw("you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)")
    
  it "throws an error if args() has already been called on the expectation", ->
    exp = new Expectation("my_method")
    exp.args(1,2,3)
    (-> exp.args("a", "b", "c") ).should.throw("you called args() more than once, e.g. my_mock.expects('my_method').args(1).args(2); call it just once")

  it "wraps strings with quotes in expection messages"
  
  
describe "Expectation.returns(value)", ->

  it "returns the Expectation instance", ->
    exp = new Expectation("my_method")
    exp.returns(123).should.equal(exp)

  it "throws an error if no 'value' argument is specified", ->
    exp = new Expectation("my_method")
    (-> exp.returns() ).should.throw("you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)")
    
  it "throws an error if returns() has already been called on the expectation", ->
    exp = new Expectation("my_method")
    exp.returns(42)
    (-> exp.returns("abc") ).should.throw("you called returns() more than once, e.g. my_mock.expects('my_method').returns(1).returns(2); call it just once")

  it "throws an error if a throws error has been previously set", ->
    exp = new Expectation("my_method").throws(new Error("an error"))
    (-> exp.returns(42) ).should.throw("you called returns() and throws() on the same expectation; use one or the other but not both")
    
  it "can be called after args()", ->
    (new Mock()).expects("my_method").args(1,2,3).returns(42)

  it "can be called before args() (but likely not good style)", ->
    (new Mock()).expects("my_method").returns(42).args(1,2,3)
    
    
describe "Expectation.throws(error)", ->
  
  it "returns the Expectation instance", ->
    exp = new Expectation("my_method")
    exp.throws(new Error("an error")).should.equal(exp)

  it "throws an error if no 'error' argument is specified", ->
    exp = new Expectation("my_method")
    (-> exp.throws() ).should.throw("you need to supply an argument to .throws(), e.g. my_mock.expects('my_method').throws('an error')")
    
  it "throws an error if throws() has already been called on the expectation", ->
    exp = new Expectation("my_method")
    exp.throws(new Error("an error"))
    (-> exp.throws(new Error("another error")) ).should.throw("you called throws() more than once, e.g. my_mock.expects('my_method').throws('something').throws('something else'); call it just once")

  it "throws an error if a return value has been previously set", ->
    exp = new Expectation("my_method").returns(42)
    (-> exp.throws(new Error("an error")) ).should.throw("you called returns() and throws() on the same expectation; use one or the other but not both")

  it "does not throw an error if a return value has been previously set on the same method with a different signature", ->
    exp1 = new Expectation("my_method").args(1,2,3).returns(42)
    exp2 = new Expectation("my_method").args(4,5,6).throws(new Error("an error"))
    
  it "can be called after args()", ->
    (new Mock()).expects("my_method").args(1,2,3).throws(new Error("an error"))

  it "can be called before args() (but likely not good style)", ->
    (new Mock()).expects("my_method").throws(new Error("an error")).args(1,2,3)


describe "Mock.my_method( [ value [, value ... ] ] )", ->

  it "does not throw an error if my_method is called and was expected", ->
    m = new Mock()
    m.expects("my_method")
    m.my_method()

  it "throws an error if my_method is called but was not expected", ->
    m = new Mock()
    (-> m.my_method() ).should.throw("has no method 'my_method'")

  it "throws an error if my_method is called with arguments but none were expected", ->
    m = new Mock()
    m.expects("my_method")
    (-> m.my_method(1,2,3) ).should.throw("my_method(1,2,3) does not match any expectations")

  it "throws an error if the args do not match any expectations", ->
    m = new Mock()
    m.expects("my_method").args(1,2,3)
    m.expects("my_method").args(4,5,6)
    (-> m.my_method(7,8,9) ).should.throw("my_method(7,8,9) does not match any expectations")

  it "returns the value specified in a .returns()", ->
    m = new Mock()
    m.expects("my_method").returns(123)
    m.my_method().should.equal(123)

  it "returns undefined if no .returns() was specified", ->
    m = new Mock()
    m.expects("my_method")
    should.not.exist(m.my_method())

  it "throws the error specified in a .throws()", ->
    m = new Mock()
    m.expects("my_method").throws("an error")
    (-> m.my_method() ).should.throw("an error")

  it "allows a method with args and the same method without args", ->
    m = new Mock()
    m.expects("my_method")
    m.expects("my_method").args(1,2,3)
    m.my_method()
    m.my_method(1,2,3)

  it "throws an error if a method requires args but is called with none", ->
    m = new Mock()
    m.expects("my_method").args(1,2,3)
    (-> m.my_method() ).should.throw("my_method() does not match any expectations")

  it "throws an error if a method signature with no args is duplicated", ->
    m = new Mock()
    m.expects("my_method")
    m.expects("my_method")
    (-> m.my_method() ).should.throw("my_method() is a duplicate expectation")

  it "throws an error if a method signature with args is duplicated", ->
    m = new Mock()
    m.expects("my_method").args(1,2,3)
    m.expects("my_method").args(1,2,3)
    (-> m.my_method(1,2,3) ).should.throw("my_method(1,2,3) is a duplicate expectation")

  it "throws an exception when the same method returns the same values", ->
    m = new Mock()
    m.expects("my_method").returns(1)
    m.expects("my_method").returns(1)
    (-> m.my_method() ).should.throw("my_method() is a duplicate expectation")

  it "throws an exception when the same method returns different values", ->
    m = new Mock()
    m.expects("my_method").returns(1)
    m.expects("my_method").returns(2)
    (-> m.my_method() ).should.throw("my_method() is a duplicate expectation")

  it "throws an exception when the same method throws the same values", ->
    m = new Mock()
    m.expects("my_method").throws("an error")
    m.expects("my_method").throws("an error")
    (-> m.my_method() ).should.throw("my_method() is a duplicate expectation")

  it "throws an exception when the same method throws different values", ->
    m = new Mock()
    m.expects("my_method").throws("an error")
    m.expects("my_method").throws("another error")
    (-> m.my_method() ).should.throw("my_method() is a duplicate expectation")


describe "Mock.expects(method_name)", ->

  it "returns an instance of Expectation", ->
    obj = new Object()
    mock ->
      obj.expects("my_method").should.be.instanceOf(Expectation)
      obj.my_method()             # otherwise we'll get an 'expectation not satisfied' error

  it "can be called many times to expect different methods", ->
    obj = new Object()
    mock ->
      obj.expects("my_method1")
      obj.expects("my_method2")
      obj.my_method1()            # otherwise we'll get an 'expectation not satisfied' error
      obj.my_method2()            # -- ditto --

  it "can be called after expected methods have been called (harmless but likely bad form)", ->
    obj = new Object()
    mock ->
      obj.expects("my_method1")
      obj.my_method1()
      obj.expects("my_method2")
      obj.my_method2()            # otherwise we'll get an 'expectation not satisfied' error

  it "throws an error if method_name is missing", ->
    obj = new Object()
    mock ->
      (-> obj.expects() ).should.throw("you need to supply a method name to .expects(), e.g. my_mock.expects('my_method')")

  it "throws an error if method_name is reserved", ->
    obj = new Object()
    mock ->
      for reserved in [ "expects", "args", "returns", "check" ]
        (-> obj.expects("#{reserved}") ).should.throw("you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name")


describe "mock( function( mock1 [, mock2 ...] ) )", ->
  
  it "Adds .expects() to Object so that it is available on all objects", ->
    mock ->
      should.exist(Object.prototype.expects)
      
  it "Removes .expects() from Object after running the passed function", ->
    mock ->
      # empty
    should.not.exist(Object.prototype.expects)
    
  it "Removes .expects() from Object when the passed function throws an exception", ->
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
    
  it.skip "checks expectations for errors", ->
    obj = new Object()
    (->
      mock ->
        obj.expects("my_method")
    ).should.throw("'my_method()' was never called")
    
  # OLD

  it "passes mock objects to the function argument", ->
    mock (my_mock1, my_mock2) ->
      my_mock1.should.respondTo "expects"
      my_mock2.should.respondTo "expects"

  it "checks the mocks for errors after invoking the function argument", ->
    (->
      mock (my_mock) ->
        my_mock.expects("my_method")
    ).should.throw( "'my_method()' was never called" )

  it "reports all mock object check failures", ->
    (->
      mock (my_mock1, my_mock2) ->
        my_mock1.expects("my_method1").args(1,2,3)
        my_mock2.expects("my_method2")
    ).should.throw( "'my_method1(1,2,3)' was never called\n'my_method2()' was never called\n" )
