function [] = pmkill(tids)
%PMKILL Kill one or several Parallel Matlab Instances.
%   PMKILL(TIDS) Kills the PM instances designated by TIDS. It cannot be
%   used to kill the calling instance, use EXIT. Should it be included it
%   will simply be ignored. Failed kills of instances will generate
%   warnings. Killing a non-existent instance does not generate a warning
  
tids = setdiff(tids,pvm_mytid);
for n=1:length(tids)
  if (pvm_kill(tids(n)) < 0)
    pvm_perror('');
    warning(['failed killing process: ' int2str(tids(n)) '.']);
  else
    pvm_delinfo(['PMCONF' int2str(tids(n))],0,0);
  end
end

