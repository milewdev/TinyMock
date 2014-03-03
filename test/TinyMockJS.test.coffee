{mock, Mock} = require("../src/TinyMockJS")


describe "Mock.expects(method_name)", ->

  it "returns the mock instance", ->
    m = new Mock()
    m.expects("my_method").should.equal m

  it "can be called many times to expect the same method", ->
    m = new Mock()
    m.expects("my_method").expects("my_method")

  it "can be called many times to expect different methods", ->
    m = new Mock()
    m.expects("my_method1").expects("my_method2")

  it "can be called after expected methods have been called (harmless but likely bad form)", ->
    m = (new Mock).expects("my_method1")
    m.my_method1()
    m.expects("my_method2")

  it "throws an error if method_name is missing", ->
    m = new Mock()
    (-> m.expects() ).should.throw( "you need to supply a method name to .expects(), e.g. my_mock.expects('my_method')" )

  it "throws an error if method_name is reserved", ->
    m = new Mock()
    for reserved in [ "expects", "args", "returns", "check" ]
      (-> m.expects("#{reserved}") ).should.throw( "you cannot do my_mock.expects('#{reserved}'); '#{reserved}' is a reserved method name" )


describe "Mock.args( value [, value ...] )", ->

  it "returns the mock instance", ->
    m = new Mock().expects("my_method")
    m.args(42).should.equal m

  it "throws an error if no 'value' arguments are specified", ->
    m = (new Mock).expects("my_method")
    (-> m.args() ).should.throw( "you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)" )

  it "throws an error if it was not called immediately after .expects()", ->
    m = new Mock()
    (-> m.args(42) ).should.throw( ".args() must be called immediately after .expects()" )
    m.expects("my_method").args(42)
    (-> m.args(43) ).should.throw( ".args() must be called immediately after .expects()" )
    m.expects("my_method").throws("an error")
    (-> m.args(44) ).should.throw( ".args() must be called immediately after .expects()" )

  it "wraps strings with quotes in expection messages"


describe "Mock.returns(value)", ->

  it "returns the mock instance", ->
    m = (new Mock).expects("my_method")
    m.returns(123).should.equal m

  it "throws an error if no 'value' argument is specified", ->
    m = (new Mock).expects("my_method")
    (-> m.returns() ).should.throw( "you need to supply an argument to .returns(), e.g. my_mock.expects('my_method').returns(123)" )

  it "can be called immediately after .expects()", ->
    m = (new Mock).expects("my_method")
    m.returns(123)

  it "can be called immediate after .args()", ->
    m = (new Mock).expects("my_method").args(1,2,3)
    m.returns(123)

  it "throws an error if it was not called immediately after either .expects() or .args()", ->
    m = new Mock()
    (-> m.returns(123) ).should.throw( ".returns() must be called immediately after .expects() or .args()" )

  it "throws an error if an error (exception) value has been previously set", ->
    m = (new Mock).expects("my_method").throws("an error")
    (-> m.returns(42) ).should.throw # anything


describe "Mock.throws(error)", ->

  it "returns the mock instance", ->
    m = (new Mock).expects("my_method")
    m.throws("an error").should.equal m

  it "throws an error if a return value has been previously set", ->
    m = (new Mock).expects("my_method").returns(42)
    (-> m.throws("an error") ).should.throw # anything

  it "does not throw an error if a return value has been previously set on the same method with a different signature", ->
    m = new Mock()
    m.expects("my_method").args(1,2,3).returns(42)
    m.expects("my_method").args(4,5,6)
    (-> m.throws("an error") ).should.not.throw

  it "throws an error if no 'error' argument is specified", ->
    m = (new Mock).expects("my_method")
    (-> m.throws() ).should.throw( "you need to supply an argument to .throws(), e.g. my_mock.expects('my_method').throws('an error')" )

  it "can be called immediately after .expects()", ->
    m = (new Mock).expects("my_method")
    m.throws("an error")

  it "can be called immediately after .args()", ->
    m = (new Mock).expects("my_method").args(1,2,3)
    m.throws("an error")

  it "throws an error if it was not called immediately after either .expects() or .args()", ->
    m = new Mock()
    (-> m.throws("an error") ).should.throw( ".throws() must be called immediately after .expects() or .args()" )


describe "Mock.my_method( [ value [, value ... ] ] )", ->

  it "does not throw an error if my_method is called and was expected", ->
    m = (new Mock).expects("my_method")
    m.my_method()

  it "throws an error if my_method is called but was not expected", ->
    m = new Mock()
    (-> m.my_method() ).should.throw( "has no method 'my_method'" )

  it "throws an error if my_method is called with arguments but none were expected", ->
    m = (new Mock).expects("my_method")
    (-> m.my_method(1,2,3) ).should.throw( "my_method(1,2,3) does not match any expectations" )

  it "throws an error if the args do not match any expectations", ->
    m = (new Mock)
      .expects("my_method").args(1,2,3)
      .expects("my_method").args(4,5,6)
    (-> m.my_method(7,8,9) ).should.throw( "my_method(7,8,9) does not match any expectations" )

  it "returns the value specified in a .returns()", ->
    m = (new Mock).expects("my_method").returns(123)
    m.my_method().should.equal 123

  it "returns undefined if no .returns() was specified", ->
    m = (new Mock).expects("my_method")
    should.not.exist m.my_method()

  it "throws the error specified in a .throws()", ->
    m = (new Mock).expects("my_method").throws("an error")
    (-> m.my_method() ).should.throw( "an error" )

  it "allows a method with args and the same method without args", ->
    m = new Mock()
    m.expects("my_method")
    m.expects("my_method").args(1,2,3)
    m.my_method()
    m.my_method(1,2,3)

  it "throws an error if a method requires args but is called with none", ->
    m = new Mock()
    m.expects("my_method").args(1,2,3)
    (-> m.my_method() ).should.throw( "my_method() does not match any expectations" )

  it "throws an error if a method signature with no args is duplicated", ->
    m = new Mock()
    m.expects("my_method")
    m.expects("my_method")
    (-> m.my_method() ).should.throw( "my_method() is a duplicate expectation" )

  it "throws an error if a method signature with args is duplicated", ->
    m = new Mock()
    m.expects("my_method").args(1,2,3)
    m.expects("my_method").args(1,2,3)
    (-> m.my_method(1,2,3) ).should.throw( "my_method(1,2,3) is a duplicate expectation" )

  it "throws an exception when the same method returns the same values", ->
    m = new Mock()
    m.expects("my_method").returns(1)
    m.expects("my_method").returns(1)
    (-> m.my_method() ).should.throw( "my_method() is a duplicate expectation" )

  it "throws an exception when the same method returns different values", ->
    m = new Mock()
    m.expects("my_method").returns(1)
    m.expects("my_method").returns(2)
    (-> m.my_method() ).should.throw( "my_method() is a duplicate expectation" )

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


describe "mock( function( mock1 [, mock2 ...] ) )", ->

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
