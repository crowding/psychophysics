function [] = pmclose()
%PMCLOSE Close the Parallel Matlab System.
%   PMCLOSE Closes the running PM if any. Cannot be called from spawned
%   matlab instances (use EXIT).
  
if ~isempty(getenv('PVMEPID'))
  error('pmclose can''t be called in spawned PM instance.')
end

if ~pmis
  return;
end

PVM_STARTER = [];
persistent2('open','PVM_STARTER')
if ~isempty(PVM_STARTER)
  if strcmp(computer,'PCWIN')
    % workaround for pvme_halt
    if pvm_exit < 0; error('pmclose: pvm_exit failed.'), end;
    pvme_unlink;
    clear m2pvm;
    dos('echo halt | pvm');
  else
    if pvme_halt < 0; error('pmclose: pvme_halt failed.'), end
  end;
  PVM_STARTER = [];
  persistent2('close','PVM_STARTER')
  fprintf('PVM was started through PMOPEN and is halted.\n');
else
  pmkill(pmothers);
  if pvm_exit < 0; error('pmclose: pvm_exit failed.'), end
  fprintf('User did not start PVM through Matlab. PVM still running\n')  
end

pvme_unlink

unsetenv('PM_IS');
PM_IS = [];
persistent2('close','PM_IS')

