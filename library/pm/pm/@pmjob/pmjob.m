%PMJOB Construct PMJOB object.
%   The PMJOB object inherits all functionality from a PMFUN object and
%   incorporates also the input, output, and virtual machine
%   information. 
%
%   JOB = PMJOB creates a default PMJOB object.
%
%   JOB = PMJOB(PMFUN,VM,INPUT,OUTPUT) creates a PMJOB object from a PMFUN
%   object.
%
%   JOB = PMJOB(EXPR,ARGIN,ARGOUT,DATAIN,DATAOUT,BLOCKS,COMARG, ...
%               COMDATA,PREFUN,POSTFUN,USERDATA,SINGLEMODE,VM,INPUT,OUTPUT)
%   Creates a PMJOB with the specified attributes. (see PMFUN)
%
%   See also DISPATCH, RPC, PMFUN.

function f = pmjob(varargin);
  
if nargin == 1 & isa(varargin{1},'pmjob')
  f = varargin{1};
  return;
end

if nargin == 0 | nargin == 1
  % default values:
  f.vm       = 0;
  f.input    = [];
  f.output   = [];
  f= class(f,'pmjob',pmfun);
  if nargin == 1 & isa(varargin{1},'pmfun')
    f.pmfun = varargin{1};
  end
  return;
end

if nargin == 12 | nargin == 4
  k = nargin - 2;
  f.vm      = varargin{k};
  f.input   = varargin{k+1};
  f.output  = varargin{k+2};
  f= class(f,'pmjob',pmfun);
  if isa(varargin{1},'pmfun')
    f.pmfun = varargin{1};
  else
    f.pmrpcfun.expr   = varargin{1};
    f.pmrpcfun.argin  = varargin{2};
    f.pmrpcfun.argout = varargin{3};
    f.datain  = varargin{4};
    f.dataout = varargin{5};
    f.prefun  = varargin{6};
    f.postfun = varargin{7};
    f.userdata = varargin{8};
    f.mode    = varargin{9};
  end
else
  error('bad number of arguments');
end



