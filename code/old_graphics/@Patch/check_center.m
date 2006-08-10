function r = checkcenter(p, c);
% verification for values of center
r = isnumeric(c) && isvector(c) && (length(c) == 3);
