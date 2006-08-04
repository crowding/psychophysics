function in = inRect(rect, x, y)
%Tests if a point is inside a given screen rectangle.
%Uses one-ended intervals; i.e. [0 0] is in [0 0 800 600] but [800 600] is
%not. This is consistent with general screen drawing behavior.

in = (x >= rect(1)) && (y >= rect(2)) && (x < rect(3)) && (y < rect(4));