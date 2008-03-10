function info=pvm_mcast(tids,msgtag)
%PVM_MCAST
%	Multicasts the data in the active message buffer to a set of tasks.	
%	
%	Synopsis:
%		info = pvm_mcast(tids,msgtag)
%
%	Parameters:
%		tids	Matrix with integer task identifiers of destination
%			processes.
%		msgtag	Integer message tag supplied by the user. Should be >=0.
%
%		info	Status code. Values less than zero indicate an error.
%			Error value	Possible cause
%			PvmBadParam	giving an invalid tid or msgtag
%			PvmSysErr	pvmd not responding
%			PvmNoBuf	no active send buffer 
%
%	Description:
%	pvm_mcast does not send to the caller even if listed in tids.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

info = m2pvm(806,tids,msgtag);

