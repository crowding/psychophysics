function r = check_spacing(this, s);

r = isnumeric(s) && isvector(s) && ( length(s) == 3 );
