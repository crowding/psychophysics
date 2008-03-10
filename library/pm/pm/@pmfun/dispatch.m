function [err, varargout] = dispatch(f,vm,varargin);
%PMFUN/DISPATCH
%   [ERR,OUTPUT1,OUTPUT2,..]=DISPATCH(PMFUN,VM,INPUT,[OUTPUT],[STATE],[CONFIG]) 
%   Dispatches a single function on the virtual machine(s) specified by
%   VM. The input needed for dispatching is taken from the cell array
%   INPUT. An output data structure OUTPUT can be predefined and should
%   be a cell array (or [] or {} if not predefined and more arguments
%   follow). STATE is a variable produced by the dispatcher itself as it
%   can be set to regularly save its state, should be empty ([]) if not
%   resuming an interrupted dispatching and more arguments are given. The
%   saved file (name is configurable) contains this variable by the name
%   'state'. CONFIG is a struct with the following fields:
%     FIELD      DEFAULT       VALID ENTRIES   
%     gui        0             0|1 boolean. If GUI should be used
%     saveinterv 100           1->Inf How often state should be saved
%     statefile  '/tmp/pmstate.mat' string Filename
%     debug      0             0|1 boolean. If output should be made
%                                  by slaves.
%     logfile    'stdout'    ('stdout' | 'stderr' | '' | filename) 
%                                  (empty -> no log)
%
%   CONFIG = DISPATCH(PMFUN,'getconfig') Retrieves the current
%   configuration of the dispatcher. If the configuration of the
%   dispatcher is changed it will remain that way until the method is
%   cleared from memory. 
%
%   DISPATCH(PMFUN,'setconfig',CONFIG) Can be used to set the
%   configuration of the dispatcher without starting the dispatch.
%
%   DISPATCH(PMFUN,'setconfig',PARAM1,VALUE1,PARAM2,VALUE2,...)
%   CONFIG can in all above functions be replaced by a set of parameters
%   and their values. A parameter is a fieldname of the configuration
%   structure, and a value is any allowed value for that parameter.
% 
%   Example:
%    inds = createinds(ones(1,10),[1 1])
%    bl = pmblock('src',inds,'dst',[inds inds])
%    f=pmfun('a=b+c',{'b'},{'a','b'},...
%            {'GETBLOC(1)'},{'SETBLOC(1)','SETBLOC(2)'},bl, ...
%            {'c'},{'INPUT(2)'},'','',[],1)
%    input = {1:10,50};
%    [err,as,bs] = dispatch(f,0,input,[],[],'gui',0)
%
%   See also PMFUN, RPC, SETCOMMON, PMBLOCK.
%
%Known bugs:
%  cancelling others processes is not stable. This is due to the signal
%  handling of the mexfiles. For now, use Single mode for all PMFUN/PMJOB. 
%  Always set timeout to Inf in PMBLOCKS. 

% uses @PMJOB/dispatch

  
if length(f)>1
  error('Cannot dispatch arrays of PMFUN. PMJOB must be used');
end

% Initialise output block if wanted.
if nargin<4 | (nargin >= 4 & isa(varargin{2},'double') & isempty(varargin{2}))
  outp = {};
else
  outp = varargin{2};
end
if nargin>2
  inp = varargin{1};
else
  inp = {};
end

job = pmjob(f,vm,inp,outp);

if nargin >= 2 & ischar(vm)
  % this is for setting or getting options
  if nargin >= 3
    dispatch(job,vm,varargin{:});
  else
    err = dispatch(job,vm);
  end
  return
end

if nargin <=4
  err = dispatch(job);
else
  err = dispatch(job,varargin{3:nargin-2});
end

varargout = cell(1,nargout-1);
varargout = getfield(job,'output');
