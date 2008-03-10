function info = pmmembvm(vmid)
%PMMEMBVM List all PMI:s members of a specific Virtual Machine. 
%   INFO = PMMEMBVM(VMID) Return ids of all Parallel Matlab instances
%   that belong to the Virtual Machine with id VMID.
%
%   INFO contains a negative PVM error code if not succesful.
%
%   See also PMEXPANDVM, PMMEMBVM, PMNEWVM.
  
% PVM constants
PvmMboxDefault = 0;
PvmNotFound = -32;

[info,nclasses,names,nentries,indices,owners,flags]=pvm_getmboxinfo('PMVM*');
if info<0
  return
end

info = [];

for n=1:nclasses
  name = deblank(names(n,:));
  if length(name) > 4
    bufid = pvm_recvinfo(name,0,PvmMboxDefault);
    if bufid < 0  &  bufid ~= PvmNotFound
      error('pmjoinvm: pvm_recvinfo() failed.')
    end
    if bufid > 0
      v = version;
      if v(1) == '4'
	vm_tbl = pvme_upkmat;
      else
	vm_tbl = pvme_upkarray;
      end
      pvm_freebuf(bufid);
    else
      vm_tbl = [];
    end
    if ~isempty(intersect(vmid,vm_tbl))
      info = [info owners{n}];
    end
  end
end

 