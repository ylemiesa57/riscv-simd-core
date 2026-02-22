# demo: set x1=10, x2=20, x3=dot(v1,v2) + x1 + x2
start:
  addi x1, x0, 10
  addi x2, x0, 20
  vdot.vv x3, x1, x2
  add x3, x3, x1
  add x3, x3, x2
  jal x0, done

done:
  addi x0, x0, 0
