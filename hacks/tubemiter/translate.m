function r = translate(vec)

r = [1      0       0       -vec(1); ...
     0      1       0       -vec(2); ...
     0      0       1       -vec(3); ...
     0      0       0       1]; ...