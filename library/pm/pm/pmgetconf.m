%PMGETCONF Return configuration of the current Parallel Matlab System
%   PMS_CONF = PMGETCONF retrieves the parallel Matlab system
%   configuration in a format that can be given to pmopen to open a
%   parallel Matlab system session. It does not necessarily contain a
%   description of the current configuration as it is, but instead it
%   contains a specification on how to rebuild the same. This is because
%   the Virtual Machine ids always start on 0 and increases when starting
%   a PMS session, whereas in the current system some Virtual machines
%   may have been deleted. The PMGETCONF assumes that it is executed on
%   the same Matlab instance on the same host from where it will be
%   started. This means that the executing Matlab instance will be the
%   originally executing Matlab process.
%
%   See also PMOPEN, PMCLOSE.
  
function pms_conf = pmgetconf

  [nhost,narch,dtids,hosts,archs,speeds,info]=pvm_config;

  % The PVM configuration is simply the hosts in the current PVM. Note
  % that if the user has started other PVM daemons outside of Matlab,
  % these will also be included since they cannot be distinguished from
  % Parallel MAtlab System hosts.
  pvm_conf = cellstr(hosts);
  
  % The VM configuration is obtained by saving the current VMs, although
  % their IDS will not necessarily be the same when restarting the
  % PMS. Example: VM 1,3,4 will become VM 0,1,2 
  vmid = vmids;
  vm_conf = cell(1,length(vmid));
  for n=1:length(vmid)
    vm_conf{n} = vmget(vmid(n));
  end
  
  % The Matlab Instance configuration
  pmi_conf = cell(1,3);
  pmi_conf{1} = pvm_conf;       % first argument to pmspawn - the hosts
  % now get the number of Matlab instances on each of these hosts.
  pmi = pmothers;               % ids of all other Matlab instances.
  num = zeros(1,length(pmi_conf{1}));
  vms_table = cell(1,length(pmi_conf{1}));
  for n = 1:length(pmi)
    host = pmhostname(pmi(n));  % host on which this matlab instance runs
    ind = find(strcmp(host,pmi_conf{1}));
    num(ind) = num(ind) + 1;
    vms = pmlistvm(pmi(n));     % VMs of this Matlab instance
    new_vms = zeros(size(vms));
    for m = 1:length(vms)
      new_vms(m) = find(vmid==vms(m))-1;
    end
    m = 1;
    while m <= size(vms_table,1) & ~isempty(vms_table{m,ind})
      m = m + 1;
    end
    vms_table{m,ind} = new_vms;
  end
  pmi_conf{2} = num;
  pmi_conf{3} = vms_table;
  
  pms_conf.pvm_conf = pvm_conf;
  pms_conf.vm_conf  = vm_conf;
  pms_conf.pmi_conf = pmi_conf;

