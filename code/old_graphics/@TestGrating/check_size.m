function r = check_size(this, s);

r = isnumeric(s) && isvector(s) && ( length(s) == 3 );
