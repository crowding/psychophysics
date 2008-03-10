function info = pmothers()
%PMOTHERS Return all the PMI:s in the PMS except the caller.
%   INFO = PMOTHERS Returns the ids of all Parallel Matlab Instances in
%   the system except the caller. It does not include other PVM processes
%   that are not linked to the Parallel Matlab System. 
%
%   See also PMALL, PMMEMBVM

[info,nclasses,names,nentries,indices,owners,flags]=pvm_getmboxinfo('PMINFO*');

info = [owners{:}];
info = setdiff(info,pvm_mytid);
