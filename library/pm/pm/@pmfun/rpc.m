function varargout = rpc(f,tids,blockind,inp,varargin)
%PMFUN/RPC Remote Procedure Call
%   RPC(PMFUN, TIDS, BLOCKIND, INPUT, [DEBUGFLAG]) Executes a remote
%   procedure call evaluating the expression contained by PMFUN on the
%   instances specified by TIDS. BLOCKIND determines which block of the
%   PMFUN that should specify the data to evalaute on. INPUT is a cell
%   array that contains the different indata specified in the PMFUN
%   object. The output (also specified by PMFUN) is sent back, but the
%   function does not block to wait for it. There must be the same number
%   of input data variables as ARGIN in the PMFUN object. The DEBUGFLAG
%   allows the user to specify whether there will be output to the screen
%   of the target Matlab console or not. Any output forced by the user,
%   e.g. by omission of ';' or by using DISP will be output. Valid values
%   are 1 (default) or 0.
%  
%   [OUTPUT1,OUTPUT2, ...] = RPC(PMFUN, TIDS, BLOCKIND, INPUT, [DEBUGFLAG])
%   does the same thing except that it blocks and waits for the result
%   before continuing its execution. The number of output arguments must
%   be coherent with the number of entries in ARGOUT of the PMFUN
%   object. 
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
%   See also PMFUN, PMRPCFUN/RPC, PMJOB/RPC, PMCLEARBUF.
  
%   Used by : @PMJOB/RPC
%   Uses:     @PMBLOCK/GETBLOC 
%   will use: @PMBLOCK/SETBLOC when fully implemented.
% Sends all variables that are not to be loaded
% Demands that all variables except the ones to be saved are
% retrieved. The ones that are to be saved will be confirmed by sending
% back 0 if succesful. Errors at load not handled nor signaled.
  
%default values
  debug = 1;

  if nargin == 5 
    if isa(varargin{1},'double') 
      debug = varargin{1};
    else
      error('bad debug flag value');
    end
  end

  argout = [];
  fileinds = [];
  argout_ind = [];
  saveind = strmatch('SAVEFILE',f.dataout);
  for n=1:size(f.pmrpcfun.argout,2),
    if ~ismember(n,saveind)
      % the output is not to be saved to file
      argout = [argout f.pmrpcfun.argout(n)];
      argout_ind = [argout_ind n];
      fileinds = [fileinds 0];
    else
      % the output argument is zero to acknowledge the save
      argout = [argout {'0'}];
      [t,r] = strtok(f.dataout{n},'(');
      fileinds = [fileinds eval(r)];
    end
  end  
  if nargout>length(argout_ind)
    error('trying to retrieve more output than specified by pmfun.argout.');
  end
  
  expr = f.pmrpcfun.expr;
  
  %make sure to tell slave to load the files that are to be loaded
  input = [];
  argin = [];
  loadind = strmatch('LOADFILE',f.datain);  
  for n=1:size(f.pmrpcfun.argin,2),
    newinp = eval(f.datain{n});
    if ~ismember(n,loadind)
      input = [input {newinp}];
      argin = [argin {f.pmrpcfun.argin{n}}];
    else
      % newinp contains the file name of a file from which the slave
      % should load the variable f.pmrpcfun.argin{n}
      expr = [['load(''' newinp ''',''' f.pmrpcfun.argin{n} ''');'] expr];
    end
  end

  % make sure to tell slave to save output files
  for n=1:length(f.blocks(blockind).dstfile)
    args = find(fileinds==n);
    args = [f.pmrpcfun.argout(args); [repmat({' '},1,length(args))]];
    args = cat(2,args{:});
    expr = [expr [',save ' f.blocks(blockind).dstfile{n} ' ' args ';']];
  end

  if nargout > 0
    % it is a blocking RPC where the user wants output!
    outp = cell(1,length(argout));
    [outp{:}]=pmrpc(tids, expr, input, argin, argout,debug);
    varargout = cell(1,nargout);
    varargout = outp(argout_ind);
  else
    pmrpc(tids, expr, input, argin, argout,debug);
  end
  


%% MACROS that allows functions to be called without parameters.
function src = SRC(varargin) 
  if nargin == 0
    src = evalin('caller','f.blocks(blockind).src');
  elseif nargin == 1 
    src = evalin('caller',['f.blocks(blockind).src{' sprintf('%d',varargin{1}) '}']);
  else
    error('bad use of SRC(n)');
  end  
    
function dst = DST(varargin) 
  if nargin == 0
  dst = evalin('caller','f.blocks(blockind).dst');
  elseif nargin == 1 
    dst = evalin('caller',['f.blocks(blockind).dst{' sprintf('%d',varargin{1}) '}']);
  else
    error('bad use of DST(n)');
  end  

function srcfile = SRCFILE(varargin) 
  if nargin == 0
    srcfile = evalin('caller','f.blocks(blockind).srcfile');
  elseif nargin == 1 
    srcfile = evalin('caller',['f.blocks(blockind).srcfile{' sprintf('%d',varargin{1}) '}']);
  else
    error('bad use of SRCFILE(n)');
  end  

function dstfile = DSTFILE(varargin) 
  if nargin == 0
  dstfile = evalin('caller','f.blocks(blockind).dstfile');
  elseif nargin == 1 
    dstfile = evalin('caller',['f.blocks(blockind).dstfile{' sprintf('%d',varargin{1}) '}']);
  else
    error('bad use of DSTFILE(n)');
  end  

function margin = MARGIN(varargin)
  if nargin == 0
    margin = evalin('caller','f.blocks(blockind).margin');
  elseif nargin == 1 
    margin = evalin('caller',['f.blocks(blockind).margin{' sprintf('%d',varargin{1}) '}']);
  else
    error('bad use of MARGIN(n)');
  end  

function userdata = USERDATA(varargin)
  if nargin == 0
    userdata = evalin('caller','f.blocks(blockind).userdata');
  elseif nargin == 1 
    userdata = evalin('caller',['f.blocks(blockind).userdata{' sprintf('%d',varargin{1}) '}']);
  else
    error('bad use of MARGIN(n)');
  end  

  %% working 3 nov 2000
function data = GETBLOC(varargin)
   if nargin == 0
     srcind = 1;
   else
     srcind = varargin{1};
   end
   evalin('caller',['tmp=inp{' int2str(srcind) '};']);
   data = evalin('caller',['getbloc(f.blocks(blockind),''tmp'',' sprintf('%d',srcind) ')']);

 %% working 3 nov 2000, no error checking! better way => do the load from
 %  the rpc-slave, to handle errors centrally.  ??

% $$$ function err = LOADFILE(varargin)
% $$$   if nargin == 0
% $$$     fname = evalin('caller','getsrcfile(f.blocks(blockind))');
% $$$   elseif nargin == 1
% $$$     fname = evalin('caller',['getsrcfile(f.blocks(blockind),' sprintf('%d',varargin{1}) ')']);
% $$$   else
% $$$     error('bad use of LOADFILE(n)');
% $$$   end
% $$$   argname = evalin('caller','f.pmrpcfun.argin{n}');
% $$$   evalin('caller',['pmeval(tids,''load(''''' fname ''''',''''' argname ''''')'',~debug);']);
% $$$   err = [];

 
  %% working 1 June, 2001  
  % returns the filename so that it can be added to be loaded through the
  % actual RPC expression.
function fname = LOADFILE(varargin)
  if nargin == 0
    fname = evalin('caller','getsrcfile(f.blocks(blockind))');
  elseif nargin == 1
    fname = evalin('caller',['getsrcfile(f.blocks(blockind),' sprintf('%d',varargin{1}) ')']);
  else
    error('bad use of LOADFILE(n)');
  end

  
  %%% following function is not verified to work for multiple output variables.
%function [] = SETBLOC(varargin)
%  if nargin == 0
%    evalin('caller','setbloc(f.blocks(blockind)),''data'');');
%  elseif nargin == 1 
%    evalin('caller',['setbloc(f.blocks(blockind)),''data'',' int2str(varargin{1}) ');']);
%  else
%    error('bad use of SETBLOC(n)');
%  end  








