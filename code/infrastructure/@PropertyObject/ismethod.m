function t = ismethod(this, method)
% Faster replacement for ismethod().

error(nargchk(2,2,nargin));

t = any(strcmp( methods(this) , method));
