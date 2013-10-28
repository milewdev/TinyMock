class Mock
  
  constructor: ->
    @call_counts = {}
    @last_method_was= undefined
  
  expects: (method_name) ->
    throw new Error("you cannot do my_mock.expects('#{method_name}'); '#{method_name}' is a reserved method name") if method_name in [ "expects", "check" ]
    @call_counts[ method_name ] ?= { expected: 0, actual: 0 }
    @call_counts[ method_name ].expected += 1
    @[ method_name ] = -> @call_counts[ method_name ].actual += 1
    @last_method_was = "expects"
    @
    
    
  args: (values...) ->
    throw new Error("you need to supply at least one argument to .args(), e.g. my_mock.expects('my_method').args(42)") if values.length == 0
    throw new Error(".args() must be called immediately after .expects(), e.g. my_mock.expects('my_method').args(42)") unless @last_method_was == "expects"
    @last_method_was = "args"
    @
    
  check: ->
    messages = ""
    for method_name, call_count of @call_counts when call_count.expected != call_count.actual
      messages += "'#{method_name}' had #{call_count.actual} calls; expected #{call_count.expected} calls\n" 
    throw new Error(messages) unless messages == ""
    @last_method_was = "check"
    @


mock = (fn) ->
  mocks = ( new Mock() for i in [1..10] )
  fn.apply(undefined, mocks)
  m.check() for m in mocks


(exports ? window).mock = mock
(exports ? window).Mock = Mock
