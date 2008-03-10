function info = setcommon(fun,tids,input,varargin)
%SETCOMMON Initialise worker instances with the common data.
%   SETCOMMON(PMFUN,TIDS,INPUT,[DEBUGFLAG]) Initialises worker instances
%   with the common data specified in PMFUN. Data can be either sent
%   directly or loaded from the worker (see PMFUN). The INPUT is the same
%   input as for the dispatcher, i.e. including input that will be sent
%   at each iteration (specific input) defined by DATAIN in PMFUN. TIDS
%   are the PVM task ids of the instances that should be intialised with
%   this data. DEBUGFLAG = 1 gives output on the worker instance
%   (default), 0 disables this. Returns the task ids of the
%   Matlab instances that have been correctly updated.
%
%   See also PMFUN.

  quiet = 0;
  if nargin == 4 & isa(varargin{1},'double')
    quiet = ~varargin{1};
  end

  RPC_catch = ['pmsend(' sprintf('%d',pmid) ' ,[''RPC_ERRORCOM'' lasterr],' ...
	       '''RPC_OUT'');fprintf(''\n??? %s\n%d>'',lasterr,pmid);'];
  
  tids = setdiff(tids,pmid); % don't send anything to caller PMI.
  if ~isempty(tids)
    for argcnt=1:length(fun.comarg)
      if strmatch('LOAD',fun.comdata{argcnt})
	[t,r] = strtok(fun.comdata{argcnt},'(');
	fileind = eval(r);
	pmeval(tids,['load(''' input{fileind} ''',''' fun.comarg{argcnt} ...
		     ''')'], RPC_catch, quiet);
      else % direct input
	if strmatch('INPUT',fun.comdata{argcnt}) % input from job-input
	  [t,r] = strtok(fun.comdata{argcnt},'(');
	  ind = eval(r);
	  inp = input{ind};
	else % input given directly in comdata-field
	  inp = fun.comdata{argcnt};
	end
	pmeval(tids,[fun.comarg{argcnt} '=pmrecv(' int2str(pmid) ');'],...
	       RPC_catch, quiet);
	pmsend(tids,inp);
      end
    end
  end
  info = tids;
  
