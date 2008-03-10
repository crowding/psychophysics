function [] = pmstate()
%PMSTATE Display the state of the PVM
%   PMSTATE Displays which hosts and tasks that are executing in the
%   PVM. Shows also Users' PVM tasks that are not MATLAB instances. 
  
% conf from PVM

if ~pmis
  disp('PMS not started.')
  return
end
  
[nhost,narch,dtids,hosts,archs,speeds,info]=pvm_config;

disp('hosts and their PVM id:s and architectures');
for i=1:length(dtids),
	disp([hosts(i,:) '   ' num2str(dtids(i)) '   ' archs(i,:)]);
end

% tasks from PVM
[ntask,tids,ptids,dtids,states,tasks,info]=pvm_tasks(0);
disp(['There are ' num2str(ntask) ' task(s) running:']) 

for i=1:length(tids),
	disp(['task id:' num2str(tids(i)) '   spawned by:' num2str(ptids(i)) '    and running on:' num2str(dtids(i))]);
end

