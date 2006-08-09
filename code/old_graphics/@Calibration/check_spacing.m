function r = check_spacing(this,d);
r = isvector(d) && length(d) == 2 && isreal(d) && all(d > 0);
