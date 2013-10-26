{Mock} = require("../src/mock")

describe "Mock", ->
  describe ".expects(method_name)", ->
    it "returns the mock instance", ->
      m = new Mock()
      m.expects("my_method").should.equal m

    it "throws an error if an unexpected method is called", ->
      m = new Mock()
      (-> m.my_method() ).should.throw( /has no method 'my_method'/ )
      
    it "does not throw an error if an expected method is called", ->
      m = new Mock()
      (-> m.my_method() ).should.not.throw
