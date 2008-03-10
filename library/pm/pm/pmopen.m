function ids = pmopen(varargin)
%PMOPEN Starts a Parallel Matlab System (PMS) session.  
%   The PMS session is based on a PVM session. If no PVM session has been
%   started (either by 'pvme_start_pvmd' or by starting it before
%   starting Matlab) a PVM session will be started first. A number of
%   Virtual Machines that specify attributes for computational resources
%   can also be setup (see VM). Any combination of Matlab Instances can
%   also be started to run in the Parallel Matlab System. The parameters
%   for starting up the system can become quite extensive for starting up
%   complex configurations. A good idea in this case could be to start up
%   a system piece by piece, and then save its configuration using
%   PMGETCONFIG that can later be used to start up the desired system.
%
%   IDS = PMOPEN Opens a default PMS session
%
%   IDS = PMOPEN(PVM_CONF) Determines the PVM configuration and open the
%   rest of the PMS as default.  PVM_CONF can be:
%     'd' : Default PVM as specified by the PVM configuration file set by
%        PVME_DEFAULT_CONFIG 
%     empty : PVM is started on the current host only
%     cell array of strings : Each string will form a line in a PVM
%        configuration file. In addition the first line always sets up the
%        PVM path correctly by containing '* ep=$PATH'. An example of
%        using this call is to let each string contain a name of a host.
%
%   IDS = PMOPEN(PVM_CONF, VM_CONF) Determines the PVM configuration and
%   the Virtual Machines it contains. A default Matlab instance
%   configuration is spawned.  VM_CONF can be:
%     'd' : Default VM created
%     Empty : No VM is created - will have to be created by the user
%             before spawning Matlab instances.
%     A configuration struct as defined as input for creating a VM (see VM) 
%     A cell array of any combination of VM attribute structures or 'd'.
%          This opens several VM.
%  
%   IDS = PMOPEN(PMS_CONF), IDS = PMOPEN(PVM_CONF, VM_CONF, PMI_CONF) 
%   Specifies the entire PMS to be opened.  PMI_CONF can be:
%     'd' : Default configuration of Matlab instances started. This will
%           start one Matlab instance on each host in the PVM.
%     Empty : no Matlab instances are started with the PMS.
%     cell : containing the arguments needed for a PMSPAWN.
%   PMS_CONF is a struct containing PVM_CONF, VM_CONF and PMI_CONF in the
%   named order. This is what is returned from PMGETCONFIG.
%
%   IDS = PMOPEN(...,'block')  or IDS = PMOPEN(...,'noblock') Determines
%   whether the command waits for the entire PMS to be set up or if it
%   does this in the background.
%
%   The output IDS contains the ids of the spawned Matlab instances if any.
%  
%   Example 1:
%      pmopen({'xenon' 'platine'},'d',{'*',2,0})
%        % opens a PVM with hosts xenon and platine, creates a default
%        % VM, and spawns two matlab instances at arbitrary hosts.
%   Example 2:
%        hosts = {'xenon' 'platine'};
%        c.wd='/my_workdir'; c.prio='low'; c.try=''; c.catch=''; c.runmode='fg'
%        pmopen(hosts,c,{hosts})
%        % opens a PVM with hosts xenon and platine
%        % spawns one Matlab instance on each host, with specified work
%        % directory and low priority.
%   Example 3:
%      c.wd=pwd; c.prio='low'; c.try='myinit'; c.catch=''; c.runmode='fg'
%      hosts = {'platine' 'xenon'}; 
%      pmopen(hosts, {'d' c}, {hosts,[1 2],{0 0 ; [] [0 1]} })
%        % opens a PVM with the hosts xenon and platine, creates one
%        % default virtual machine and one that has been specified by the
%        % user to start its matlab instances with lower priority, and 
%        % also to execute the function 'myinit' when newly spawned.
%        % Then, one Matlab instance will be started on platine, and two
%        % on xenon. The second matlab instance on xenon will belong to
%        % both virtual machines (0,1) and the first only to the default (0)
%
%   See also PMCLOSE, PMGETCONFIG, PMSPAWN, VM, VMGET.
  

%Definitions
% Routing policies: the default is PvmAllowDirect
%  PvmDontRoute   = 1
%  PvmAllowDirect = 2 (default)
%  PvmRouteDirect = 3
%Route = 3; 
  
if ~isempty(getenv('PVMEPID'))
	error('pmopen can''t be called from spawned Matlab instance.')
end

PM_IS = [];
persistent2('open','PM_IS')

if ~isempty(PM_IS)
  disp('PMS already running');
  return
end

% default values - if no arguments given! 
block = 'block';
pvm_conf = 'd'; % 
vm_conf = {'d'};
pmi_conf = 'd';

%%%--- Check arguments

% last argument decides if blocking or not?
nin = nargin;
if nargin >= 1 & ischar(varargin{nargin})
  if any(strcmp(varargin{nargin},{'block','noblock'}))
    nin = nin - 1;
    block = varargin{nargin};
  end
end
% now _nin_ is the number of varargin.

%--- Check if a structure as one returned from PMGETCONFIG
if nin == 1 & isstruct(varargin{1})
  args = struct2cell(varargin{1});
  ids = pmopen(args{:},block);
  return
end

%--- Check PVM_CONFIG argument
if nin >= 1 
  if ischar(varargin{1})
    pvm_conf = strvcat({'* ep=$PATH' varargin{1}});
  elseif iscell(varargin{1})
    pvm_conf = strvcat([{'* ep=$PATH'} varargin{1}]);
  elseif ~isempty(varargin{1})
    error('bad PVM configuration argument')
  end
end
%--- Check VM_CONFIG argument
if nin >= 2 
  % make it into a cell if it wasn't already
  if isempty(varargin{2})
    vm_conf = varargin{2};
  else
    if iscell(varargin{2})
      vm_conf = varargin{2};
    else
      vm_conf = varargin(2);
    end
    % scan through arguments
    for cnf_arg = vm_conf
      cnf_arg = cnf_arg{:};
      if ischar(cnf_arg)
	if ~any(strcmp(cnf_arg,{'d'}))
	  error('bad Virtual machine attributes argument');
	end
      elseif isstruct(cnf_arg)
	if ~isequal(fieldnames(cnf_arg),{'wd' 'prio' 'try' 'catch' 'runmode'}')
	error('bad Virtual Machine attribute structure')
	end
      elseif ~isempty(cnf_arg)
	error(['vm configuration must be: empty, ''d'', attribute structure' ...
	       ' or a cell array of a combination of these'])
      end
    end
  end
end
%--- Check PMI_CONF argument
if nin == 3
  if ischar(varargin{3})
    if ~any(strcmp(varargin{3},'d'))
      error('bad Virtual machine attributes argument');
    end
  end
  pmi_conf = varargin{3};
end


%%% Starting PVM

pvme_link
pvm_setopt(3,0); % turn off output from PVM!
fprintf('Starting PVM...');
info = pvme_start_pvmd(pvm_conf,1);
if info == -28 %duplicate host
  fprintf('PVM already started.\n');
else
  if info < 0
    error(['pvme_start_pvmd failed.' int2str(info)])
  end
  fprintf('OK\n');
  PVM_STARTER = 1;
  persistent2('close','PVM_STARTER');
end

fprintf('This Matlab instance is joined to the PVM with the id %d\n',pvm_mytid);
PM_IS = 1;
persistent2('close','PM_IS');
putenv('PM_IS=TRUE');

[nhost,narch,dtids,hosts,archs,speeds,info]=pvm_config;
fprintf('%d host(s) in PVM :',nhost);
for n=1:nhost,
  fprintf(' %s',deblank(hosts(n,:)));
end
fprintf('\n\n');


%%% Creating VM attributes.

if ~isempty(vm_conf)
  for vm_conf_arg = vm_conf
    vm(vm_conf_arg{:});
  end
  ids = vmids;
  fprintf('Created %d Virtual Machine(s)\n',length(ids));
  for id = ids
    fprintf('Virtual Machine #%d:',id);
    if isequal(vm_conf{id+1},'d')
      fprintf('(default)\n')
    else
      fprintf('\n')
    end
    disp(vmget(id))
  end
end

%%% Spawning Matlab instances

if ~isempty(pmi_conf)
  if ischar(pmi_conf)
    if strcmp(pmi_conf,'d')
      % default config. Try if a VM is already created
      fprintf('Default configuration, spawning into VM #0\n')
      try,
	vmget(0);  % first VM
      catch
	fprintf('Virtual Machine #0 do not exist, creating default:\n')
	vm;  % didn't exist, so create it!
	vmget(0)
      end
      pmi_conf = {cellstr(hosts)',1,0,repmat({'/dev/null'},1,length(hosts))};
    end
  end
  % spawn!!!
  ids = pmspawn(pmi_conf{:},block,'verbose');
end


conf.vm = [];
conf.outredir = 'Console';
	  
bufid = pvm_initsend(0);
v = version;
if v(1) == '4'
  pvme_pkmat(conf,'');
else
  pvme_pkarray(conf,'');
end
pvm_putinfo(['PMCONF' int2str(pmid)],bufid,5); % PMCONF
pvm_freebuf(bufid);

% start in INTERACTIVE mode.
pm_setinfo(0,'');









