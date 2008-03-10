function info = setcommon(job,tids,varargin)
%SETCOMMON Set common (initialisation) variables for PMJOB(s) to workers.
%   INFO = SETCOMMON(PMJOB,TIDS,[DEBUGFLAG])
%   See PMFUN/SETCOMMON. This method does exactly the same thing however
%   it can be applied to a vector of PMJOBs. Returns the task ids of the
%   Matlab instances that have been correctly updated.
%
%   See also PMJOB.
  
info = [];  
numfun = length(job);
for n=1:numfun,
  if ~isempty(job(n).pmfun.comarg)
    tids2 = pmmembvm(job(n).vm);
    if ~isempty(tids)
      tids2 = intersect(tids2, tids);
    end  
    if isempty(tids2)
      if isempty(tids)
	warning(['No common variables will be sent to job with index ' int2str(n)]);
      end
    else
      info = [info setcommon(job(n).pmfun,tids2,job(n).input,varargin{:})];
    end
  end
end
info = unique(info);


