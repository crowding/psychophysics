function src = SRC(bl,varargin) 
  if nargin == 1
    src = bl.src;
  elseif nargin == 2
    src = bl.src{varargin{1}};
  else
    error('bad use of GETSRC(n)');
  end  
