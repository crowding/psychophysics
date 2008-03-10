function tid = pvm_parent()
%PVM_PARENT
%	Returns the tid of the process that spawned the calling process.
%	TID=PVM_PARENT returns TID<0 if the calling process has no parent.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

tid=m2pvm(401);

