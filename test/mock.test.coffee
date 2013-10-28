{mock, Mock} = require("../src/mock")



describe "Mock.expects(method_name)", ->
  
  it "returns the mock instance", ->
    m = new Mock()
    m.expects("my_method").should.equal m
    
  it "can be called many times to expect the same method", ->
    m = (new Mock).expects("my_method").expects("my_method")
    m.my_method()
    
  it "can be called many times to expect different methods", ->
    m = (new Mock).expects("my_method1").expects("my_method2")
    m.my_method1()
    m.my_method2()
    
  it "can be called after expected methods have been called (harmless but likely bad form)", ->
    m = (new Mock).expects("my_method1")
    m.my_method1()
    m.expects("my_method2")
    m.my_method2()
    
  it "throws an error if method_name is 'expects'", ->
    m = new Mock()
    (-> m.expects("expects") ).should.throw( "you cannot do my_mock.expects('expects'); 'expects' is a reserved method name" )
    
  it "throws an error if method_name is 'check'", ->
    m = new Mock()
    (-> m.expects("check") ).should.throw( "you cannot do my_mock.expects('check'); 'check' is a reserved method name" )
    
    
    
describe "Mock.with( value [, value ...] )", ->

  it "returns the mock instance"

  it "throws an error if no 'value' arguments are specified", ->
    m = new Mock()
    (-> m.expects("my_method").with() ).should.throw( "you need to supply at least one argument to .with(), e.g. my_mock.expects('my_method').with(42)" )
    
  it "throws an error if expect() has not been called yet"
  
  
  
describe "Mock.my_method( [ value [, value ... ] ] )", ->

  it "does not throw an error if my_method is called and was expected", ->
    m = (new Mock).expects("my_method")
    m.my_method()

  it "throws an error if my_method is called but was not expected", ->
    m = new Mock()
    (-> m.my_method() ).should.throw( "has no method 'my_method'" )

  it "does not throw an error if my_method is called with arguments but none were expected"
  
  it "throws an error if my_method is called with the wrong number of arguments"
  
  it "throws an error if my_method is called with the wrong type of arguments"


  
describe "Mock.check()", ->
  
  it "can be called many times (meaningless but harmless)", ->
    m = (new Mock).expects("my_method")
    m.my_method()
    m.check()
    m.check()

  it "can be called many times in any order (harmless but likely bad form)", ->
    m = (new Mock).expects("my_method1")
    m.my_method1()
    m.check()
    m.expects("my_method2")
    m.my_method2()
    m.check()

  # revisit all below in light of .with()
  
  it.skip "does not throw an error if an expected method was called", ->
    m = (new Mock).expects("my_method")
    m.my_method()
    m.check()
  
  it.skip "throws an error if an expected method was not called", ->
    m = (new Mock).expects("my_method")
    (-> m.check() ).should.throw( "'my_method' had 0 calls; expected 1 call" )
      
  it.skip "does not throw an error if a method is called the expected number of times", ->
    m = (new Mock).expects("my_method").expects("my_method")
    m.my_method() ; m.my_method()
    m.check()
    
  it.skip "throws an error if a method is called too few times", ->
    m = (new Mock).expects("my_method").expects("my_method")
    m.my_method()
    (-> m.check() ).should.throw( "'my_method' had 1 calls; expected 2 calls" )
  
  it.skip "throws an error if a method is called too many times", ->
    m = (new Mock).expects("my_method").expects("my_method")
    m.my_method() ; m.my_method() ; m.my_method()
    (-> m.check() ).should.throw( "'my_method' had 3 calls; expected 2 calls" )
    
  it.skip "reports all all methods that were called an incorrect number of times", ->
    m = (new Mock).expects("my_method1").expects("my_method2")
    (-> m.check() ).should.throw( /my_method1(.|\n)*?my_method2/ )
    
    
    
describe "mock( function( mock1 [, mock2 ...] ) )", ->
  
  it "passes mock objects to the function argument", ->
    mock (my_mock1, my_mock2) ->
      my_mock1.should.respondTo "expects"
      my_mock2.should.respondTo "expects"

  it "invokes Mock.check on the mock object after invoking the function argument", ->
    my_mock_reference = false
    mock (my_mock) ->
      my_mock.check = -> my_mock_reference = true     # Don't try this at home.
    my_mock_reference.should.equal true
    
  it "does not eat expections thrown by Mock.check", ->
    (->
      mock (my_mock) ->
        my_mock.expects("my_method")
    ).should.throw( "'my_method' had 0 calls; expected 1 calls" )
