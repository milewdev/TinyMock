f = (x) ->
  for x_local in [x..x+1] 
    do (y = x_local) -> -> console.log(y)
  
f1 = f(1)

for a in f1
  a()

f2 = f(2)

for b in f2
  b()

for c in f1
  c()

for d in f2
  d()
