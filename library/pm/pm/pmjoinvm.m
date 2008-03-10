function info = pmjoinvm(vmid)
%PMJOINVM Join a Virtual Machine
%   INFO = PMJOINVM(VMID) The calling PMI joins an existing Virtual
%   Machine. If already a member, nothing is done. INFO contains all
%   VMID:s of VM:s that the current PMI is a member of after the
%   adhesion. If the VM does not exist -1 is returned.
%
%   See also PMMEMBVM, PMNEWVM, PMQUITVM.

  % constants
  PvmDataDefault      = 0;
  PvmMboxDefault      = 0;
  PvmNotFound         = -32;
  
  if ~ismember(vmid,vmids)
    info = -1;
    return
  end
  
  
  % load VM data
  info = [];
  vm_table = ['PMVM' int2str(pmid)];
  bufid = pvm_recvinfo(vm_table,0,PvmMboxDefault);
  if bufid < 0  &  bufid ~= PvmNotFound
    error('pmjoinvm: pvm_recvinfo() failed.')
  end
  if bufid > 0
    v = version;
    if v(1) == '4'
      info = pvme_upkmat;
    else
      info = pvme_upkarray;
    end
    pvm_freebuf(bufid);
  end
  
  % add the vmid to this PMI:s list of member vmid
  if ismember(vmid,info)
    return
  else
    info = [info vmid]; 
  end
  
  % update VM data.
  bufid = pvm_initsend(PvmDataDefault);
  v = version;
  if v(1) == '4'
    pvme_pkmat(info,'');
  else
    pvme_pkarray(info,'');
  end
  pvm_putinfo(vm_table,bufid,PvmMboxDefault);
  pvm_freebuf(bufid);