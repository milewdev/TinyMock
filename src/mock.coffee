class Mock
  
  initialize: ->
    @called = 0
  
  expects: (method_name) ->
    @method_name = method_name
    @called = 1
    @[ method_name ] = -> @called = 2
    @
    
  check: ->
    throw new Error("'#{@method_name}' was never called") if @called == 1


(exports ? window).Mock = Mock
