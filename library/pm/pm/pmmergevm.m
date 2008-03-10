function [] = pmmergevm(vmids)
%PMMERGEVM Merges several Virtual Machines.
%   PMMERGEVM(VMIDS) Merges the VM:s in VMIDS. VMIDS is an array of at
%   least two vmids. The produced VM will have the lower of the vmids of
%   all the merged Virtual machines. All PMI:s concerned have to be in
%   extern mode. (see PMEXTERN, PMGETMODE). If not, it is not guaranteed
%   that VM:s will merge completely. 
%
%   See also PMLISTVM, PMMEMBVM, PMNEWVM, PMEXTERN, PMGETMODE.
  
if length(vmids) < 2 | ~isa(vmids,'double')
  error('bad arguments.');
end

newvm = vmids(1);
vmids = vmids(2:end);

for n=length(vmids)
  memb = pmmembvm(vmids(n));
  pmeval(memb,['pmjoinvm(' int2str(newvm) ');pmquitvm(' int2str(vmids(n)) ');'])
end   


