function mstat = pvm_mstat(host)
%PVM_MSTAT 
%	Returns the status of a host in the virtual machine.
%	
%	Synopsis:
%		mstat = pvm_mstat(host)
%
%	Parameters:
%		host	String containing the host name.
%
%		mstat	Integer scalar returning the machine status.
%			Status 	   	Possible cause
%		 	PvmOk		Host is o.k.
%		 	PvmNoHost	Host is not in virtual machine.
%		     	PvmHostFail	Host is unreachable (possibly failed).
%			PvmSysErr	pvmd not responding.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse

mstat=m2pvm(403,host);

