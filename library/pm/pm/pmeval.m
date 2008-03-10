function [] = pmeval(tids,expr,varargin)
%PMEVAL Evaluate a Matlab expression on Matlab instance(s) in the PMS.
%   PMEVAL(TIDS,EXPR) evaluates the string EXPR on the Matlab instances
%   designated by the array TIDS of PMI ids. 
%
%   If a PMI does not exist a Warning will be issued and the instance
%   skipped. If a PMI is not in EXTERN mode and able to accept the
%   evaluation request, a Warning will be issued and the evaluation
%   request will be queued and executed as soon as the target PMI is set
%   to EXTERN mode.
%  
%   Two global variables will automatically be accessible on the target
%   instances:
%     PMEVALPARENT the ID of the PMI that requested the evaluation. 
%     PMEVALIDS    the IDS of other PMI:s that received the same request.
% 
%   PMEVAL(TIDS,TRY,CATCH) Tries evaluating the expression TRY and if it
%   fails the error will be caught and the CATCH expression
%   evaluated. 
%
%   PMEVAL(...,QUIET) Allows the user to decide if the evaluation should
%   print the evaluation expression or not. Possible values are 0 or
%   positive. 1 is default which means that the expression will be
%   printed to the screen.
%
%   Example:
%     pmeval(pmothers,'a = rand(10);',0) 
%  
%   See also EVAL, PMEXTERN, PMGETMODE.
  
%constants  
PvmDataDefault = 0;
DpmmSysTag1    = 9010;

quiet_mode = 'N';
nin = nargin;
if nin >= 3 & isa(varargin{nin-2},'double')
  nin = nin -1;
  if varargin{nin-1}
    quiet_mode = 'Q';
  end
end
if nin == 3
  catchexp = ['#' varargin{1}];
else
  catchexp = '';
end  

me = pvm_mytid;

% check whether caller is among destinations or if no target given.
if any(tids == me) 
  tids = tids(tids~=me);
  also_caller = 1;
else
  also_caller = 0;
end

% verify the target PMI:s
for n=1:length(tids),
  [mode,info]=pmgetinfo(tids(n));
  if isempty(mode)
    warning(['PMI with id : ' int2str(tids(n)) ' does not exist.'])
    tids(n) = [];
  elseif mode == 0 
    warning(['PMI with id : ' int2str(tids(n)) ' is not in extern mode.']);
  end
end

cmd1 = ['global PMEVALPARENT, PMEVALPARENT=' sprintf('%d',me) '; '];
tids = tids(:)';
cmd2 = ['global PMEVALIDS, PMEVALIDS=' mat2str(tids) '; '];
extended_exp = [quiet_mode sprintf('%d',length([cmd1 cmd2])+1) ...
		'#' cmd1 cmd2 expr catchexp];

% eval on caller if necessary
if also_caller 
	evalin('caller',[cmd1 cmd2])
	fprintf('1:%d>%d>> %s\n',me,me,expr)
	if isempty(catchexp)
	  evalin('caller',expr)
	else
	  evalin('caller',expr,catchexpr)
	end
	evalin('caller','clear global PMEVALPARENT, clear global PMEVALIDS')
end

% eval on foreign destinations
bufid = pvm_initsend(PvmDataDefault);
v = version;
if v(1) == '4'
	pvme_pkmat(extended_exp,'');
else
	pvme_pkarray(extended_exp,'');
end
pvm_mcast(tids,DpmmSysTag1);
pvm_freebuf(bufid);




