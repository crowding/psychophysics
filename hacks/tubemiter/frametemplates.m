tubemiter(1.25-1.8/25.4, 1.25, 1.5,  rotatex(93.1))
text(0,0,'LT(f) to HT 93.1°')
print -depsc ltf-ht.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125,  rotatex(84.9))
text(0,0,'LT(f) to ST 84.9°')
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

tubemiter(1.25-1.8/25.4, 1.25, 1.125, rotatex(103.7))
text(0,0,'TTr to STf 103.7')
print -depsc ttr-stf2.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125,  rotatex(95.1))
text(0,0,'LT(r) to ST(f) 95.1°')
print -depsc ltr-stf.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125,  rotatex(93.8))
text(0,0,'LT(r) to ST(f) 93.8° (raised)')
print -depsc ltr-stf2.eps

tubemiter(1.5-1.8/25.4, 1.5, 2.375, rotatey(90), 1.125, rotatex(75))
text(0,0,'BT to EBB+ST(f) 75')
print -depsc bt-ebb.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125, rotatex(78.2))
text(0,0,'TTr to STr 78.2')
print -depsc ttr-str.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.125, rotatex(76.3))
text(0,0,'TTr to STr 76.3')
print -depsc ttr-str2.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.5,  rotatey(90.0), 1.125, rotatex(84.9), 1.5, rotatex(20.9))
text(0,0,'LTr to RBB complex')
print -depsc lt-rbb.eps

tubemiter(1.25-1.8/25.4, 1.25, 1.5,  rotatey(90.0)*translate([0 1 0])*rotatex(4.2), 1.125, rotatex(86.2), 1.5, rotatex(-15.7)*translate([0 1 0]) * rotatex(-4.2))
text(0,0,'LTr to RBB complex2')
print -depsc lt-rbb2.eps

tubemiter(1.5-1.8/25.4, 1.5, 1.5, rotatey(90), 1.125, rotatex(105.7))
text(0,0,'BT to rBB+ST(r) 105.7')
print -depsc bt-rbb.eps
