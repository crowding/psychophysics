function dtid=pvm_tidtohost(tid)
%PVM_TIDTOHOST 
%	Returns the host ID on which the specified task is running.
%
%	Synopsis:
%		dtid = pvm_tidtohost(tid)
%
%	Parameters:
%		tid	Integer scalar specifying a task id.
%
%		dtid	Integer Scalar returning the host id. Values less
%			than zero indicate an error:
%			Value		Meaning
%			PvmBadParam	giving an invalid tid.
%			PvmSysErr	pvmd not responding.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

dtid=m2pvm(406,tid);

