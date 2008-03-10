function tid = pvm_mytid()
%PVM_MYTID
%	Returns the TID of the process.
%	TID=PVM_MYTID enrolls this process into PVM on its first call and
%	generates a unique TID if this process was not created by PVM_SPAWN.
%	It can be called multiple times. 
%
%	If PVM has not been started before an application calls PVM_MYTID the
%	returned TID will be < 0.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

tid=m2pvm(400);

