function [] = pmquitvm(vmid)
%PMQUITVM Leave a VM 
%   PMQUITVM(VMID) The current PMI leaves the specified VM. If the
%   current PMI is not a member of the specified VM, nothing happens.
%
%   See also PMJOINVM, PMMEMBVM, PMLISTVM.
  
  % constants
  PvmDataDefault      = 0;
  PvmMboxDefault      = 0;
  PvmNotFound         = -32;
  
  % load VM data
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
  else
    info = [];
  end
  
  info(find(info==vmid)) = [];
  
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






