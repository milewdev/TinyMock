class Mock
  
  constructor: ->
    @call_counts = {}
  
  expects: (method_name) ->
    throw new Error("you cannot do my_mock.expects('#{method_name}'); '#{method_name}' is a reserved method name") if method_name in [ "expects", "check" ]
    @call_counts[ method_name ] ?= { expected: 0, actual: 0 }
    @call_counts[ method_name ].expected += 1
    @[ method_name ] = -> @call_counts[ method_name ].actual += 1
    @
    
    
  with: (args...) ->
    throw new Error("you need to supply at least one argument to .with(), e.g. my_mock.expects('my_method').with(42)") if args.length == 0
    
  check: ->
    messages = ""
    for method_name, call_count of @call_counts when call_count.expected != call_count.actual
      messages += "'#{method_name}' had #{call_count.actual} calls; expected #{call_count.expected} calls\n" 
    throw new Error(messages) unless messages == ""


mock = (fn) ->
  mocks = ( new Mock() for i in [1..10] )
  fn.apply(undefined, mocks)
  m.check() for m in mocks


(exports ? window).mock = mock
(exports ? window).Mock = Mock
