function varargout = rpc(rpcfun,tids, varargin)
%PMRPCFUN/RPC Remote Procedure Call
%   RPC(PMRPCFUN, TIDS, DATAIN1, DATAIN2, ...) Executes a remote
%   procedure call evaluating the expression contained by PMRPCFUN on the
%   instances specified by TIDS. DATAIN1, DATAIN2, ... correspond to the
%   different indata specified in the PMRPCFUN object. The output
%   (also specified by PMRPCFUN) is sent back, but the function does not
%   block to wait for it. There must be the same number of input data
%   variables as ARGIN in the PMRPCFUN object.
%  
%   [OUTPUT1,OUTPUT2, ...] = RPC(RPCFUN, TIDS, DATAIN1, DATAIN2, ...,)
%   does the same thing except that it blocks and waits for the result
%   before continuing its execution. The number of output arguments must
%   be coherent with the number of entries in ARGOUT of the PMRPCFUN
%   object. 
%
%   ... PMRPCFUN(...,'Debug',debugflag) allows the user to specify
%   whether the will be output to the screen of the target Matlab console
%   or not. Any output forced by the user, e.g. by omission of ; or by
%   using DISP will be output.
%
%   Examples:
%     n=100000;x=rand(n,1);y=rand(n,1);z=rand(n,1);
%     [X,Y] = meshgrid(0:0.1:1, 0:0.1:1);
%     f=pmrpcfun('[XI,YI,ZI]=griddata(x,y,z,X,Y);',...
%                {'x','y','z','X','Y'}, {'XI','YI','ZI'});
%     %to wait for result:
%     [XI,YI,ZI] = rpc(f,262146,x,y,z,X,Y,'Debug',1); mesh(XI,YI,ZI);
%     %to not wait for result:
%     rpc(f,262146,x,y,z,X,Y,'Debug',1);
%     % ... execute other code
%     outp = pmrecv('RPC_OUT'); mesh(outp{:})
%
%   See also PMRPCFUN, PMFUN/RPC, PMJOB/RPC, PMCLEARBUF.
    
%default
debug = 1;

if nargin>3 & isa(varargin{nargin-3},'char') & (nargin-2)==(size(rpcfun.argin,2)+2)
  if strcmp(varargin{nargin-3},'Debug')
    debug = varargin{nargin-2};
  else
    error('check number of in arguments. Debugflag not correct.')
  end
  nin = nargin-4;
else
  if (nargin-2) ~= size(rpcfun.argin,2)
    error(['Bad number of input arguments. Must be coherent with the input' ...
	   ' arguments specified in pmrpcfun.']);
  end
  nin = nargin-2;
end

if nargout > 0
  varargout = cell(1,nargout);
  [varargout{:}]=pmrpc(tids,rpcfun.expr,{varargin{1:nin}},rpcfun.argin,rpcfun.argout,debug);
else
  pmrpc(tids,rpcfun.expr,{varargin{1:nin}},rpcfun.argin,rpcfun.argout,debug);
end
