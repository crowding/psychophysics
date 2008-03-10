function status = pvm_pstat(tid)
%PVM_PSTAT 
%	Returns the status of the specified PVM process.
%	STATUS=PVM_PSTAT(TID) returns one of the following conditions
%	of the process identified by TID:
%		Status value		Possible cause
%		  (0)PvmOk		Task is running.
%		 (-2)PvmBadParam	Bad Parameter most likely invalid tid.
%		(-14)PvmSysErr		pvmd not responding.
%		(-31)PvmNoTask		Task not running.
%
%	Also note that PVM_NOTIFY can be used to notify the caller 
%	that a task has failed.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

status=m2pvm(402,tid);

