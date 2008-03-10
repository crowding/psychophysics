%PMRPC Remote Remote Call
%   Procedure Remote Call - sends variables to distant PMI, evaluates an
%   expression and retrieves chosen variables.
%
%   [OUT1, OUT2, ...] = PMRPC(TID, EXPR, INPUT, ARGIN, ARGOUT,[DEBUGFLAG]) 
%    TID    specifies the id of the target PMI. Only one allowed if
%           output arguments (OUTn) are specified.
%    EXPR   is the expression to evaluate. 
%    INPUT  is a cell array of input data
%    ARGIN  is a cell array specifying the names that the input data will
%           take on the target host.
%    ARGOUT is a cell array specifying the names of variables to retrieve.
%    DEBUGFLAG specifies whether debugging output should be output on the
%           target PMI. 1 means yes (default), 0 no.
%    OUTn   are the output arguments. Must be less output arguments than
%           number of variables specified as output (by ARGOUT). Output
%           specified in ARGOUT but with no corresponding output arguments
%           will be lost if at least one other output argument is
%           specified. If an error occurs at the target PMI during
%           evaluation the PMRPC gives an error message.
%
%   If no output arguments are specified the function is non-blocking and
%   will return immediately after requesting the evaluation on the target
%   PMI. Using the non-blocking RPC the reception of the output is left
%   to the user. The message returned from an RPC is called 'RPC_OUT'. If
%   an error occurred in the target PMI, RPC_OUT is a string beginning by
%   the string 'RPC_ERROR' and followed by the error message issued in
%   the target PMI. If no error occurred RPC_OUT contains the output
%   arguments in a cell array.
% 
%   Example
%     Blocking RPC sending variable b, retrieving variable a into aa.
%         aa = pmrpc(262146,'a=b+1;',{3},{'b'},{'a'})
%     Non-blocking RPC 
%         pmrpc(262146,'a=b+1;c=rand(10).*b;',{3},{'b'},{'a' 'c'},0)
%         aa = pmrecv(262146,'RPC_OUT') 
%         a = aa{1}; c=aa{2};  %assuming no error
%
%   See also PMEVAL, PMEXTERN


function varargout = pmrpc(slave, expr,input,argin,argout,varargin)

  me = sprintf('%d',pvm_mytid);
  
  % what to do in a slave when error caught:
  RPC_catch = ['pmsend(' me ' ,[''RPC_ERROR'' lasterr],' ...
	       '''RPC_OUT'');fprintf(''\n??? %s\n%d>'',lasterr,pmid);'];

  if nargout>0 & length(slave)>1
    error('pmrpc cannot be used on multiple instances when blocking.')
  end
        
  RPC_IN.func = expr;
  RPC_IN.in = [argin; input];
  RPC_IN.out = argout;
  if nargin == 6 & isa(varargin{1},'double')
    RPC_IN.debug = varargin{1};
  else
    RPC_IN.debug = 1;
  end
  
  if nargout>length(RPC_IN.out)
    error('trying to receive more arguments than output from RPC')
  end
  
  pmeval(slave,['pm_rpcslave(' me ')'],RPC_catch,1);
  pmsend(slave, RPC_IN, 'RPC_IN');

  % wait for return data?
  if nargout>0
    RPC_OUT = pmrecv(slave,'RPC_OUT');
    if isa(RPC_OUT,'char') & ~iscell(RPC_OUT) & strcmp('RPC_ERROR',RPC_OUT(1:9))
      error(['Error in target PMI:: ' RPC_OUT(10:end)])
    else
      for n=1:nargout,
	varargout{n} = RPC_OUT{n};
      end
    end
  end


  
  
  
  
  
  
