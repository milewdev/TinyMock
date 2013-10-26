{Mock} = require("../src/mock")

describe "Mock", ->
  describe ".expects(method_name)", ->
    it "returns the mock instance", ->
      m = new Mock()
      m.expects("my_method").should.equal m
      
    it "does not throw an error if an expected method is called", ->
      m = new Mock()
      (-> m.my_method() ).should.not.throw

    it "throws an error if an unexpected method is called", ->
      m = new Mock()
      (-> m.my_method() ).should.throw( /has no method 'my_method'/ )

  describe ".check()", ->
    it "does not throw an error if an expected method was called", ->
      m = (new Mock).expects("my_method")
      m.my_method()
      (-> m.check() ).should.not.throw
    
    it "throws an error if an expected method was not called", ->
      m = (new Mock).expects("my_method")
      (-> m.check() ).should.throw( /'my_method' was never called/ )
  