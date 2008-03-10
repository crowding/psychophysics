function varargout = rpc(job,tids,blockind,varargin)
%PMJOB/RPC Remote Procedure Call
%   [OUTP] =RPC(PMJOB,TIDS,BLOCKIND,[DEBUGFLAG])
%   See PMFUN/RPC. This method does exactly the same thing and is
%   different only in the input arguments. Those input arguments not
%   specified for the PMJOB/RPC but for PMFUN/RPC are already
%   incorporated in the PMJOB, whereas they need to be provided for
%   PMFUN. If OUTP is specified the method is blocking. 
%
%   See also PMJOB, PMFUN, PMFUN/RPC. 
  
%   Uses    : @PMFUN/RPC

% default
  debug = 1;
  
  if nargin == 4 
    if isa(varargin{1},'double') 
      debug = varargin{1};
    else
      error('bad debug flag value');
    end
  end

if nargout > 0
  nout = length(strmatch('SETBLOC',job.pmfun.dataout));
  job.output = cell(1,nout);
  [job.output{:}] = rpc(job.pmfun, tids, blockind,job.input,debug);
  varargout{1} = job;
else 
  rpc(job.pmfun, tids, blockind,job.input,debug);
end











