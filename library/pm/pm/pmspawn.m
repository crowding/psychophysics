function ids = pmspawn(varargin)
%PMSPAWN Spawn new Matlab instances into a Virtual Machine  
%   IDS = PMSPAWN Starts one Matlab instance into the default VM (0) on a
%   by pmspawn chosen host in the current PVM. VM 0 must already exist.
%    
%   IDS = PMSPAWN(LOCATION) Starts one Matlab instance on each location
%   specified. A default VM (0) must already exist. LOCATION can be a
%   string or a cell array of strings each specifying a host name in the
%   current PVM. It can also be one of the following strings:
%    '.' or 'localhost'    - spawn on this host
%    '*'   (default)       - pmspawn chooses location any where in PVM
%    'LINUX' or 'SUN4SOL2' - only on computers of a choosen platform.   
%
%   IDS = PMSPAWN(LOCATION,NUM) As above, but the number of Matlab
%   instances to start on each host can be specified. If NUM is a double
%   NUM matlab instances will be spawned on each host. If NUM is an array
%   of doubles it specifies for each host how many Matlab instances to
%   spawn. In the latter case lenght(NUM) must be equal to the number of
%   hosts specified.
%
%   IDS = PMSPAWN(LOCATION,NUM,VM) Spawns Matlab instances into specific
%   Virtual Machines. VM contains indices to the actual VM objects that
%   specify things such as work directory, priority and runmode for the
%   Matlab instance. If VM is a double or an array of doubles, all
%   spawned Matlab instances will belong to this/these VM(s). If VM is a
%   cell array of double arrays, each cell define to which VM(s) the
%   Matlab instances on each host belong. In this case the number of
%   cells in the cell array must be equal to the number of hosts
%   specified. If VM is a cell matrix each line contains further
%   information for each Matlab instance to spawn. Example: 
%     NUM = [1 2]; 
%     VM = { 0  [0 1] ; []      0 }
%     Now the instance on host 1 will belong to VM #0, the first instance
%     on host 2 will belong to VM #0 and #1. The second Matlab instance
%     on host 2 will belong to VM #0. 
%   
%   IDS = PMSPAWN(LOCATION, NUM, VM, OUTREDIR) This works as the
%   previous, but allows also to specify to where the standard output
%   from the Matlab instance should be directed in case the VM specifies
%   that the Matlab instances run in backgrund mode (i.e. with no console
%   window for input/output). OUTREDIR is a structure containing a number
%   of filenames. Default is '/dev/null' which will discard the output
%   from the Matlab console. Note that the same filename should not be
%   used for different consoles! The structure of the filenames is as the
%   structure for VM in the fully expanded case. 
%
%   IDS = PMSPAWN(..., 'block') or IDS = PMSPAWN(..., 'noblock')
%   determines whether the spawn should block until the Matlab instances
%   have started (default) or if they should be started in the background
%
%   Example 1: (spawn 2 Matlab on each of the hosts xenon and platine)
%      ids = pmspawn({'xenon' 'platine'},2,0)    % Spawned into VM 0. 
%   Example 2: (spawn background Matlab: 2 on xenon, 1 on platine)
%      c.wd=pwd; c.prio='low'; c.try=''; c.catch=''; c.runmode='bg';
%      vmid = vm(c); 
%      outpfiles = {'file1.log' 'file2.log' ; 'file3.log'  '' };
%      ids = pmspawn({'xenon' 'platine'}, [2 1], vmid, outpfiles); 
%      
%   See also PMKILL, PMOPEN, VM, VMGET, VMID.
  

%      pmspawn(loc,num,cm,outredir,[block])
%
%loc    : (cell array of) char array :    '.' | 'localhost' | 'ARCH' | '*' | hostname
%	    default: '*'
%num      : (array of) double, number of matlab instances on this host
%            (or for respective host)
%	    default 1
%vmids    : cell array (length num) of double arrays, which cmids for each pmi.
%           If not valid cmids, the corresponding PMI:s will not be spawned, and a warning issued.
%           default 0
%outredir : file to which the standard output is redirected. 
%  	    default '/dev/null'
%block    : 'block' | 'noblock'     
%           Redirection of background Matlab instance standard output.  
%  
% 
  
% constants
PvmTaskDefault = 0;
PvmTaskHost    = 1;
PvmTaskArch    = 2;
SysMsgCode1    = 9001;
MAX_PROC       = 32; % This can be modified for specific needs. Security
                     % for not starting too many processes by mistake.

display = getenv('DISPLAY'); % Display
if ~isempty(display)
  if findstr(':',display) == 1  % DISPLAY contains hostname?
    display = [getenv('HOST') display];     % if not, add it!
  end
end 

% defaults
num      = 1;
loc    = {'*'}; num_loc = 1;
vmid     = 0;
outredir = '/dev/null';
block    = 1;
verbose  = 0;  % for debugging, and used by pmopen. A last argin
               % 'verbose' turns this on!


% last or second last argument decides if blocking or not.
% the one (or two) last arguments are for 'debug' (and 'verbose')
nin = nargin;
for n=1:2
  if nin >= 1
    if ischar(varargin{nin})
      if strcmp('block',varargin{nin})
	block = 1;
	nin = nin - 1;
      elseif strcmp('noblock',varargin{nin})
	block = 0;
	nin = nin -1;
      elseif strcmp('verbose',varargin{nin})
	verbose = 1;
	nin = nin -1;
      end
    end
  end
end
% now _nin_ is the number of varargin.

%-- Verify LOC argument
if nin >= 1
  if ischar(varargin{1})
    loc = varargin(1);
  elseif iscell(varargin{1})
    ch_true = 1;
    for wh = varargin{1}
      ch_true = ch_true & ischar(wh{:});
    end
    if ~ch_true
      error(['all entries to the cell specifying a location to spawn Matlab' ...
	     ' instances must be strings.'])
    end
    loc = varargin{1};
  else
    error(['destination for spawn must be a character array or a cell array' ...
	   ' of such.'])
  end
  num_loc = length(loc);
end
%-- Verify NUM argument
if nin >= 2
  if ~isa(varargin{2},'double')
    error('first argument must be a double or array of doubles')
  end
  n_num = length(varargin{2});
  if n_num > 1 & num_loc ~= n_num
    error(['different number of destinations for spawning does not correspond' ...
	   ' list of number of instances to spawn at each destination.'])
  end
  if n_num == 1 & num_loc > 1
    num = repmat(varargin{2},1,num_loc);
  else
    num = varargin{2};
  end
else
  % expand default num:
  num = repmat(num,1,num_loc);
end

% -- Verify VMID argument
if nin >= 3
  if iscell(varargin{3})
    if ~isa([varargin{3}{:}],'double')
      error(['cell array of vmids must contain only doubles or double' ...
	     ' arrays'])
    end
  elseif ~isa(varargin{3},'double')
    error('vmids must be (an array of) double, or a cell array of such')
  end
  vmid = varargin{3};
  % verifier les fully expanded...
end
% expand vmid:
if isa(vmid,'double')
  vmid = repmat({vmid},1,num_loc);
end
if iscell(vmid) & size(vmid,2) ~= num_loc
  error(['The number of cell entries does not correspond to the number' ...
	   ' of locations to spawn'])
end
  % fully expanded:
  %  {[1 2] [1] [1] [1] ;
  %   [1]   [1] [2] []  ;
  %   []    [1] []  []   }
  %    2     3   2   1   <= corresponding num_vector
  
  % a single double array [x1 x2...] will be expanded to a cell array of
  % length num_loc. This  
  
%-- Verify outredir argument
if nin >= 4
  if ischar(varargin{4})
    outredir = varargin(4);
  elseif iscell(varargin{4})
    ch_true = 1;
    wh_list = varargin{4};
    wh_list = varargin{4}(:); 
    for wh = wh_list'
      ch_true = ch_true & (ischar(wh{:}) | isempty(wh{:}));
    end
    if ~ch_true
      error(['all entries to the cell specifying a redirection files' ...
	     ' must be strings.'])
    end
    outredir = varargin{4};
  else
    error(['output redirection must be a string (if only spawning one' ...
	   ' matlab instance) or a cell array of such.'])
  end

  if size(vmid,1) <= 1
    % vmid needs to be fully expanded if there are output redirections
    vmid = repmat(vmid,max(num),1);
  end
  
  for n = 1:num_loc
    nn = 1;
    while nn <= num(n) 
      vm_curr_id = vmid{nn,n};
      cnf = vmget(vm_curr_id(1));
      if strcmp('bg',cnf.runmode)
	if isempty(outredir{nn,n})
	  break
	end
      end
      nn = nn +1;
    end
    if nn-1 ~= num(n)
      error(['on host: ' loc{n} ', the matlab instance output redirection' ...
	     ' #' int2str(nn) ' is not defined']);
    end
  end
end
% nothing is transported via environ by pvm
unsetenv('PVM_EXPORT');

% do spawning
cmd = 'dpmatlab';

% clear reception queue for process acknowledgements.
if block
  bufid = pvm_probe(-1, SysMsgCode1); 
  while bufid~=0,
    info = pvm_freebuf(bufid);
    if info ~= 0
      break;
    end
    bufid = pvm_probe(-1,SysMsgCode1);
  end
end

if verbose
  fprintf('Spawning...\n')
end
ids = [];
for n = 1:length(loc)
  loc2s = loc{n};
  loc_exist = 1;
  if strcmp(loc2s,'*')
    % host chosen by pvm
    flag  = PvmTaskDefault;
  elseif strcmp(loc2s,'.') | strcmp(loc2s,'local') | ...
	strcmp(loc2s,'localhost')
    % local host
    flag  = PvmTaskHost;
    loc2s = '.';
  else
    % host or arch
    [nhost,trash,trash,hosts,archs] = pvm_config;
    if any(strcmp(loc2s,cellstr(hosts)))
      % host !
      flag = PvmTaskHost;
    elseif any(strcmp(loc2s,cellstr(archs)))
      % arch !
      flag = PvmTaskArch;
    else
      % unknown
      warning(['The current Parallel Matlab System does not contain ' ...
	       loc2s '. Skipped!'])
      loc_exist = 0; % continue not supported in Matlab 5.
    end
  end
  
  if loc_exist
    num2s = num(n);       % numbers of instances to spawn on this location
    
    if size(vmid,1) > 1   % we have a fully expanded structure of VMIDS
      num_spawn = num2s;  % spawn them one by one!!
      num2s = 1;
    else
      num_spawn = 1;
    end
   
    for m = 1:num_spawn
      vmid2s = vmid{m,n};  % vmids of the target MAtlab instance
      try,
	vmattr = vmget(vmid2s(1));  % the attributes of the first of these VM:s
	
	argv =    	        ['DISPLAY='	   ,display];
	argv = str2mat(argv,['PMSPAWN_BLOCK='  ,int2str(block)]);
	argv = str2mat(argv,['PMSPAWN_WD='	   ,vmattr.wd]);
	argv = str2mat(argv,['PMSPAWN_RUNMODE=',vmattr.runmode]);
	argv = str2mat(argv,['PMSPAWN_TRY='	   ,vmattr.try]);
	argv = str2mat(argv,['PMSPAWN_CATCH='  ,vmattr.catch]);
	argv = str2mat(argv,['PMSPAWN_VM='     ,int2str(vmid2s)]);    
	v = version;
	argv = str2mat(argv,  v(1));
	argv = str2mat(argv,  vmattr.prio);
	if strcmp(vmattr.runmode,'bg')
	  outredir2s = outredir{m,n};
	else
	  outredir2s = 'console';
	end
	argv = str2mat(argv,  outredir2s);
	
	[new_ids,numt] = pvm_spawn(cmd, argv, flag, loc2s, num2s);
	
	if verbose
	  fprintf('%d task(s) to VM # %s, on host %s.  id(s): %s', ...
		  num2s,int2str(vmid2s),loc2s,int2str(new_ids))
	  if strcmp(vmattr.runmode,'bg')
	    fprintf(', output -> %s\n',outredir2s) 
	  else
	    fprintf('\n')
	  end
	end
	
	% save configuration information on PMI
	%--------------------------------------
	% This is needed for fault recovery, if a Matlab instance dies it can be
	% reinstated with the same attributes.
	
	if numt > 0;
	  conf.vm = vmid2s;
	  conf.outredir = outredir2s;
	  
	  for k=1:length(new_ids)
	    bufid = pvm_initsend(0);
	    v = version;
	    if v(1) == '4'
	      pvme_pkmat(conf,'');
	    else
	      pvme_pkarray(conf,'');
	    end
	    pvm_putinfo(['PMCONF' int2str(new_ids(k))],bufid,5); % PMCONF
	    pvm_freebuf(bufid);
	  end  
	end
	ids = [ids new_ids];
	
      catch,
	warning(['Spawning to non-existent VM #' int2str(vmid2s(1)) '. ' ...
		 int2str(num2s) ' Matlab instance(s) on ' loc2s ' not spawned']) 
	error(lasterr)
      end
    end
  end
end

% receive ids from successfully spawned tasks
if block
  if verbose
    fprintf('Received acknowledgement of succesful spawning from...\n');
  end
  for n = find(ids>0)
    bufid = pvm_recv(-1,SysMsgCode1);
    ids(n) = pvm_upkdouble(1,1);
    if verbose
      fprintf(' %d', ids(n));
    end
    pvm_freebuf(bufid);
  end
end






