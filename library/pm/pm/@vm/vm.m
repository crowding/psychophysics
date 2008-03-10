%VM Constructor for Virtual Machine (VM) object.
%   The virtual machines are used to define the computation
%   resources. First, the VM defines the configuration parameters for
%   starting up Parallel Matlab Instances (PMI) (see PMSPAWN). A Virtual
%   Machine must exist before a Matlab instance is started from the
%   Parallel Matlab System, because it defines attributes that are needed
%   for spawning the Matlab instance. Second, the VM define which
%   resources that will be used when dispatching a function (see DISPATCH). 
%   Basically, when dispatching a defined job it must also be specified
%   which virtual machines that will be available for the calculation.
%   One Matlab instance may belong to one or several virtual machines.
%   The VM object is stored in a globally accessible memory so as to be
%   reachable from all Matlab instances. When refererring to an object
%   a unique VM id is used.
%
%   VM(CONF) creates a VM object with the given attributes. CONF is a
%   struct with the following fields:
%   Field     Meaning                         Possible values             
%    .wd       Working directory               String containing path
%    .prio     Priority                        'same' | 'normal' | 'low'   
%    .try      Try expression at PMI startup   Matlab expression to evaluate
%    .catch    Catch expression for try        Matlab expression to evaluate
%    .runmode  PMIs in background/forground    'bg' | 'fg'
%
%   VM creates a default VM object
%    .wd       pwd  (the current directory)
%    .prio     'normal'
%    .try      ''
%    .catch    ''
%    .runmode  'fg'
%
%   See also PMSPAWN, VMIDS, VMGET, DISPATCH

function vmid = vm(varargin)

%PvmMboxDefault = 0;
%PvmMboxPersistent = 1;
%PvmMboxMultiInstance = 2;
%PvmMboxOverWritable = 4;
  
  if nargin==1 & isstruct(varargin{1})
    if isequal(fieldnames(varargin{1}),{'wd' 'prio' 'try' 'catch' 'runmode'}')
      cnf = varargin{1};
    else
      error('Structure not coherent with VM attribute structure')
    end
  else
    % default values
    cnf.wd      = pwd;       % Working directory          
    cnf.prio    = 'normal';  % Priority                      'same' | 'normal' | 'low'
    cnf.try     = '';        % Try expression
    cnf.catch   = '';        % Catch expression for try
    cnf.runmode = 'fg';      % Run in background/forground   'bg' | 'fg'
  end
  
  bufid = pvm_initsend(0);
  v = version;
  if v(1) == '4'
    pvme_pkmat(cnf,'');
  else
    pvme_pkarray(cnf,'');
  end
  vmid = pvm_putinfo(['PMVM'],bufid,7);
  pvm_freebuf(bufid);

 