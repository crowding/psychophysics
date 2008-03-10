%PMFUN Construct a PMFUN object.
%   FUN = PMFUN creates a default PMFUN object.
%   
%   FUN = PMFUN(PMRPCFUN) creates a PMFUN object from a PMRPCFUN
%
%   FUN = PMFUN(PMRPCFUN,DATAIN,DATAOUT,BLOCKS,COMARG,COMDATA, ...
%               PREFUN,POSTFUN,USERDATA,SINGLEMODE)
%   FUN = PMFUN(EXPR,ARGIN,ARGOUT,DATAIN,DATAOUT,BLOCKS,COMARG, ...
%               COMDATA,PREFUN,POSTFUN,USERDATA,SINGLEMODE)
%   Create a PMFUN from the given parameters. The significance of the
%   parameters are:
%    EXPR       Expression to be evaluated on other instance(s)
%    ARGIN      Cell array of name(s) that data sent before each
%               evaluation will take on other instance(s). 
%    ARGOUT     Cell array of name(s) of data to be retrieved from other
%               instance(s) after each evaluation.
%    DATAIN     Cell array of expression(s) that when evaluated give the
%               actual data to be sent for each ARGIN. Following
%               expressions access the information in the PMBLOCKS for
%               each specific evalution:
%                'GETBLOC(SRC_IND)'  See PMBLOCK/GETBLOC. The input data
%                   will be taken from the input number SRC_IND to the
%                   dispatcher. The SRC_IND has thus two functions: To
%                   index into which input data and to index into which
%                   set of indices (from the SRC of PMBLOCK) to use.
%                'LOADFILE(SRCFILE_IND)' Tells the worker instance to  
%                   load the corresponding variable (in ARGIN) from the
%                   file specified by 'srcfile' (in PMBLOCK) and
%                   SRCFILE_IND.
%                'SRC(IND)'      These last seven strings specifies to 
%                'DST(IND)'      send the actual field entry of specified
%                'SRCFILE(IND)'  field. IND is the index into the field.
%                'DSTFILE(IND)'  
%                'USERDATA(IND)'
%                'MARGIN(IND)'   
%                'TIMEOUT(IND)'
%    DATAOUT    Cell array of expressions that will be evaluated when
%               data is returned from each evaluation. The following
%               predefined strings can be used:
%                'SETBLOC(IND)'  See PMBLOCK/SETBLOC
%                'SAVEFILE(IND)' Tells the worker instance to save the
%                   corresponding variable (in ARGOUT) to the file
%                   specified by 'dstfile' (in PMBLOCK) and IND.  
%    BLOCKS     PMBLOCKs
%    COMARG     Cell array of names of data provided to all worker
%               instances before dispatching commences.
%    COMDATA    Cell array of expressions that will be evaluated to
%               produce the data to send to all worker instances before
%               dispatching begins. The following predefined expressions
%               exist (INP_IND must be greater than the number of
%               GETBLOC(s) in DATAIN):
%                'LOADFILE(INP_IND)' Tells the worker instance to load
%                  the corresponding variable (in COMARG) from the file 
%                  specified by input number INP_IND to the dispatcher.
%                'INPUT(INP_IND)' Gets the data from dispatcher input
%                  number INP_IND.
%    PREFUN     Expression that will be evaluated on worker instances
%               before dispatching begins
%    POSTFUN    Expression to be evaluated on worker instances after
%               dispatching has terminated.
%    USERDATA   Reserved for the user.
%    SINGLEMODE Specifies if this function can evaluate the same block on
%               different worker instances at the same time (0) or not
%               (1). Default is 1. THIS SHOULD BE 1 IN THIS VERSION OF
%               THE PARALELL MATLAB TOOLBOX.
%
%   See also PMBLOCK, SETBLOC, GETBLOC, SETCOMMON, RPC, DISPATCH.


function f = pmfun(varargin);
  
if nargin == 1 & isa(varargin{1},'pmfun')
  f = varargin{1};
  return;
end

if nargin == 0 | nargin == 1
% default values:
  f.datain   = [];
  f.dataout  = [];
  f.blocks   = [];
  f.comarg   = [];
  f.comdata  = [];
%  f.recvfun  = '';
  f.prefun   = '';
  f.postfun  = '';
  f.userdata = [];
  f.singlemode = 1;
  f= class(f,'pmfun',pmrpcfun);
  if nargin == 1 & isa(varargin{1},'pmrpcfun')
    f.pmrpcfun = varargin{1};
  end
  return;
end

if nargin == 12 | nargin == 10
  k = nargin - 8;
  f.datain  = varargin{k};
  f.dataout = varargin{k+1};
  f.blocks  = varargin{k+2};
  f.comarg  = varargin{k+3};
  f.comdata = varargin{k+4};
%  f.recvfun = varargin{k+5};
  f.prefun  = varargin{k+5};
  f.postfun = varargin{k+6};
  f.userdata = varargin{k+7};
  f.singlemode = varargin{k+8};
  f= class(f,'pmfun',pmrpcfun);
  if isa(varargin{1},'pmrpcfun')
    f.pmrpcfun = varargin{1};
  else
    f.pmrpcfun = pmrpcfun(varargin{1},varargin{2},varargin{3});
  end
else
  error('bad number of arguments');
end



