function dst = DST(bl,varargin) 
  if nargin == 1
    dst = bl.dst;
  elseif nargin == 2
    dst = bl.dst{varargin{1}};
  else
    error('bad use of GETDST(pmblock,n)');
  end  
