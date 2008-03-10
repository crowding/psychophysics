%VMIDS Returns the ids of the Virtual Machines in the system
%   IDS = VMIDS
%   This method is different from the PMLISTVM in that it always returns
%   all VMs defined, whereas PMLISTVM is used to verify the VMIDs of a
%   specific Matlab instance.
% 
%   See also VMGET, VM, VMDEL, PMLISTVM.

function ids = vmids()
  
PvmMboxDefault = 0;
%PvmMboxPersistent = 1;
%PvmMboxMultiInstance = 2;
%PvmMboxOverWritable = 4;

[info,nclasses,names,nentries,indices]=pvm_getmboxinfo('PMVM');
if info < 0
  error (['error in cmids: ' sprintf('%d',info)]);
end
ids = [];
for n = 1:nclasses,
  if strcmp(deblank(names(n,:)),'PMVM')
    ids = indices{n};
    break;
  end
end


