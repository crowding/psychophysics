function r = check_size(c, s);

r = isnumeric(s) && isvector(s) && ( length(s) == 3 );
