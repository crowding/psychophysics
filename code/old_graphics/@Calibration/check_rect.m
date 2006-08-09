function r = check_rect(this, s)
r = isvector(s) && length(s) == 2 && all(r > 0) && all(round(r) == r) && isreal(r);
