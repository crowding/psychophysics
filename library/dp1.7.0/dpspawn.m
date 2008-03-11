function tids=dpspawn(host,command,workdir)
% tids=dpspawn(host,command,workdir)
%
% Spawns Matlab instances on HOST, changes into WORKDIR and executes
% COMMAND.
%
% HOST,COMMAND,WORKDIR must be single strings or cell arrays of strings.
% HOST is optional, default is local host ('.')
% COMMAND is optional, default is no command (just start Matlab)
% WORKDIR is optional, default WORKDIR is PWD.
% TIDS is an array of PVM task identifiers.
%
% Examples: 
%     
% tids=dpspawn
%   Spawns on local host, executes no command
%
% tids=dpspawn('.','ls') 
%   Spawns on local host, executes 'ls'.
%     
% tids=dpspawn({'host1','host2'},{'1+1','2+2'},'/') 
%   Spawns on host1 and host2, executes '1+1' on host1, '2+2' on host2, 
%   working directory is '/' on both hosts.

if nargin<3 
    workdir=pwd;
end
if ischar(workdir)
    workdir={workdir};
end
if ~iscellstr(workdir)
    error('WORKDIR must be a cell array of strings or single string.');
end

if nargin<2
    command='';
end
if ischar(command)
    command={command};
end
if ~iscellstr(command)
    error('COMMAND must be a cell array of strings or single string.');
end

if nargin<1
    host='.';
end
if ischar(host)
    host={host};
end
if ~iscellstr(host)
    error('HOST must be a cell array of strings or single string.');
end

display=getenv('DISPLAY');
if display(1)==':'
    display=[getenv('HOSTNAME'),display];
end

tids=zeros(numel(host),1);
for i=1:length(host)
    if numel(host)==numel(command)
        c=command{i};
    else
        c=command{1};
    end
    
    if numel(host)==numel(workdir)
        wd=workdir{i};
    else
        wd=workdir{1};
    end
        
    runcommand=['cd ',wd,';',c];
    
    [numt,tids(i)]=pvm_spawn('/usr/bin/xterm',{'-display',display,...
        '-e','matlab','-nodesktop','-r',runcommand},...
        1,host{i},1);
end

