function r = check_screen(this,n)
%screen neumbers should be non-negative integers
r = isscalar(n) && n >= 0 && real(round(n)) == n;
