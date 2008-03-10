%PM_SPAWNSTARTUP Startup script for spawned PMI:s, for internal use only
%
%	It has to be evaluated during startup, therefore it should be called 
%	in startup.m and after that never more.
 
% This function is based on dpspawn_startup.m:
%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta (1995, initial version)
%			    (Dec 98, rewritten)
%			    (Dec 98, revised for M4/M5 & UNIX/WIN32 compat.)
%          E. Svahn :
%          Aug 2000, window name for unix added. 
%          Nov 2000, name changed from DPSPAWN_STARTUP to PMSPAWN_STARTUP
%                    DPPARENT removed from environment parameters.
%                    Non-blocking functionality added.
%                    automatic join of Virtual Machine added.

function [] = pmspawn_startup()

echo on

PvmDataDefault = 0;
SysMsgCode1      = 9001;


unsetenv('PVM_EXPORT');

pvme_link

% RunMode:
%---------
RunMode = getenv('PMSPAWN_RUNMODE'); unsetenv('PMSPAWN_RUNMODE');
if strcmp(RunMode,'bg')
  BACKGROUND = 1;
  persistent2('close','BACKGROUND');
else 
  BACKGROUND = 0; 
end

% set window title:
%------------------ 
if isunix & ~BACKGROUND
  fprintf(['\033]0;' getenv('HOST') ' - ' sprintf('%d',pvm_mytid) '\007'])
end

% change to specified directory:
%------------------------------- 
Wd = getenv('PMSPAWN_WD'); unsetenv('PMSPAWN_WD');
v = version;
if v(1) == '4'
	isdir = ~isempty(ls(Wd));
else
	isdir = exist(Wd)==7;
end
if isdir
	cd(Wd)
else
	disp(['Can''t change directory to: ' Wd])
	disp('Directory does not exist.')
end;


% exchange parent/child ids:
%---------------------------
Block = getenv('PMSPAWN_BLOCK'); unsetenv('PMSPAWN_BLOCK');
Block = str2num(Block);
if Block

  bufid = pvm_initsend(PvmDataDefault);
  if bufid <0
    pvm_perror('');
    error('PMSPAWN_startup: pvm_initsend failed.')
  end
  
  info = pvm_pkdouble(pvm_mytid,1,1);
  if info <0
    pvm_perror('');
    error('PMSPAWN_startup: pvm_pkdouble failed.')
  end
  
  info = pvm_send(pmparent,SysMsgCode1);
  if info <0
    pvm_perror('');
    error('PMSPAWN_startup: pvm_send failed.')
  end
end

% PMI is in interactive mode until pmextern starts
%-------------------------------------------------
pm_setinfo(0,'starting matlab instance...');

% join VM:
%---------
vmid = getenv('PMSPAWN_VM'); unsetenv('PMSPAWN_VM')
pmjoinvm(str2num(vmid));


% evaluate Try, Catch:
%---------------------
Try   = getenv('PMSPAWN_TRY');   unsetenv('PMSPAWN_TRY');
Catch = getenv('PMSPAWN_CATCH'); unsetenv('PMSPAWN_CATCH');
if ~isempty(Try)
	if ~isempty(Catch)
	  fprintf('Evaluating Try expression\n%s\nWith catch expression\n%s\n',Try,Catch);
	  evalin('caller',Try,Catch)
	else
          fprintf('Evaluating Try expression\n%s\nWithout catch expression\n',Try); 
 	  evalin('caller',Try)
	end
end
