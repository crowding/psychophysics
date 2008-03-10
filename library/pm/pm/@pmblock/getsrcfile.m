function srcfile = GETSRCFILE(bl,varargin) 
  if nargin == 1
    srcfile = bl.srcfile;
  elseif nargin == 2
    srcfile = bl.srcfile{varargin{1}};
  else
    error('bad use of GETSRCFILE(n)');
  end  
