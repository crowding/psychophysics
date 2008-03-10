function info=pvm_sendsig(tid,signum)
%PVM_SENDSIG
%	Sends a signal to another PVM process.
%	
%	Synopsis:
%		info = pvm_sendsig(tid,signum)
%
%	Parameters:
%		tid	Integer scalar containig a task id of a PVM process to
%			receive the signal.
%		signum	Integer scalar containig the signal number to send.
%
%		info	Integer scalar returning the status of the routine.
%			Values less than zero indicate an error:
%			Value		Meaning	
%			PvmBadParam	giving an invalid tid.
%			PvmSysErr	pvmd not responding.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse

info=m2pvm(500,tid,signum);

