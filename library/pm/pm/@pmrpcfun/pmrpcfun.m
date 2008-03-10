%PMRPCFUN Construct PMRPCFUN object
%   The PMRPCFUN is an object used for facilitating Remote Procedure
%   Calls. The object contains the definition of a function expression
%   and input/output arguments, for its method RPC.
%
%   PMRPCFUN Creates a default PMRPCFUN object. The default attributes are:
%    expr    = ''  Expression to be evaluated on other instance(s)
%    argin   = {}  Where sent data will be stored on node
%    argout  = {}  Data that will be retrieved from node. 
%
%   PMRPCFUN(EXPR,ARGIN,ARGOUT) constructs a PMRPCFUN object with the
%   attritues specified. EXPR is a string and defines the evaluataion
%   expression, ARGIN defines the names that the input data should take
%   on the Matlab instance where the expression is evaluated and ARGOUT
%   specifies which variables to retrieve from this Matlab instance after
%   the expression. Both ARGIN and ARGOUT are cell arrays of strings.
%
%   PMRPCFUN(FUN) Creates a copy of the PMRPCFUN object FUN.
%
%   See also PMPRCFUN/RPC

function f = pmrpcfun(varargin);
  
% default values:
  f.expr     = '';
  f.argin   = {};
  f.argout  = {};
  
if nargin == 0
  
elseif nargin == 1
  if isa(varargin{1},'pmrpcfun')
    f = varargin{1};
    return;
  elseif ischar(varargin{1})
    error ('automatic expression recognition not yet supported');
  else
    error ('Bad input');
  end
elseif ~ischar(varargin{1})
  error ('first input argument should be char array or PMRPCFUN object.');
elseif nargin==3
    f.expr = varargin{1};
    f.argin   = varargin{2};
    f.argout  = varargin{3};
else
  error('bad number of arguments');
end

f= class(f,'pmrpcfun');







