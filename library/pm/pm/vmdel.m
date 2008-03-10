%VMDEL VM Object destructor
%   INFO = VMDEL(VMIDS) deletes the VM object(s) specified by (an array of) id.
%   A VM object cannot be deleted if there are currently Matlab
%   instances that are members of this VM. For each VMID specified by
%   VMIDS zero is returned if VM successfully deleted and -1 if not.

function info = vmdel(ids)
  
info = ones(size(ids)).*-1;
for n=1:length(ids)
  if isempty(pmmembvm(ids(n))) 
    info(n) = pvm_delinfo('PMVM',ids(n),0);
  end
end
