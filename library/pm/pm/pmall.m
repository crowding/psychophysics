function info = pmall()
%PMALL Returns the ID:s of all the PMI:s in the Parallel Matlab System
%   INFO=PMALL
%   INFO is the PMI ID(s) of all Parallel Matlab Instances in the system.
%   Does not include other PVM processes that are not linked to the PMS.

[info,nclasses,names,nentries,indices,owners,flags]=pvm_getmboxinfo('PMINFO*');

info = [owners{:}];
