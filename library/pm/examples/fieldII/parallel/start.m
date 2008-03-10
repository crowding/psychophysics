% This is an example of how the parallel Matlab session can be started
% using pmopen. When this is done, the user has access to all started
% Matlab processes from the original Matlab console. 
% 
% Make sure to change the hostnames in this file to names of hosts in
% _your_ network that are accessible by rsh (or ssh - depending on how
% PVM is configured) WITHOUT ASKING FOR PASSWORD.

hosts = {'platine' 'xenon' 'neon' 'radon'}; % hostnames
num = [1]; % one Matlab process on each host.

%define a Virtual Machine - the computation machine for the problem
v.wd      = pwd; % work directory
v.prio    = 'same';   % run matlab processes with same priority as this process
v.try     = '';       % no initialisation of hosts.
v.catch   = '';     
v.runmode = 'bg';     % run matlab processes in background

% each Matlab instance will have an output file with its console output:

for m=1:length(hosts)
  for n=1:num(min(length(num),m))
    console_out_files{n,m} = ['/tmp/pm_stdout' int2str(n)];
  end
end
 
% Now, open the Parallel Matlab System session

pmopen(hosts, v, {hosts,num,0,console_out_files})


% The system is now ready for your parallel applications!

% To close the system type: 'pmclose' in this console.
