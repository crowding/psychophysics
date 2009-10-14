tubemiter(1.25-1.8/25.4, 1.25, 1.5,  rotatex(86.6))
text(0,0,'LT(f) to HT 86.6°')
print -depsc ltf-ht.pdf

tubemiter(1.25-1.8/25.4, 1.25, 1.125,  rotatex(85.1))
text(0,0,'LT(f) to ST 85.1°')
print -depsc ltf-stf.eps

tubemiter(1.25-1.8/25.4, 1.25, 2.375,  rotatey(90.0))
text(0,0,'DT to EBB 90')
print -depsc dt-ebb.eps

tubemiter(1.125-1.8/25.4, 1.125, 2.375,  rotatey(90.0))
text(0,0,'ST(f) to EBB 90')
print -depsc stf-ebb.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125, rotatex(101.8))
text(0,0,'TTr to STf 101.8')
print -depsc ttr-stf.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125,  rotatex(94.9))
text(0,0,'LT(r) to ST(f) 94.9°')
print -depsc ltr-stf.eps

tubemiter(1.5-1.8/25.4, 1.5, 2.375, rotatey(90), 1.125, rotatex(75))
text(0,0,'BT to EBB+ST(f) 75')
print -depsc bt-ebb.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125, rotatex(78.2))
text(0,0,'TTr to STr 78.2')
print -depsc ttr-str.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.5,  rotatey(90.0), 1.125, rotatex(85.1), 1.5, rotatex(20.7))
text(0,0,'LTr to RBB complex')
print -depsc lt-rbb.eps

tubemiter(1.5-1.8/25.4, 1.5, 1.5, rotatey(90), 1.125, rotatex(105.7))
text(0,0,'BT to rBB+ST(r) 105.7')
print -depsc bt-rbb.eps
