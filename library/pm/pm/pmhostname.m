function name = pmhostname(id)
%PMHOSTNAME Return hostname
%   NAME = PMHOSTNAME(ID) Returns a string containing the hostname from
%   the host/PMI id provided by ID. It also returns hostname for
%   processes that do not exist, but whos id correspond to a certain
%   host. Returns empty if id is < 262144. 
  
id = pvm_tidtohost(id);
  
[nhost,narch,dtids,hosts,archs,speeds,info]=pvm_config;

name = deblank(hosts(find(dtids==id), :));

