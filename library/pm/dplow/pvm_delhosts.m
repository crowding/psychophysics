function [INFOS,info] = pvm_delhosts(HOSTS)
%PVM_DELHOSTS
%	Delete one or more hosts of the virtual machine.
%
%	Synopsis:
%		[INFOS,info] = pvm_delhosts(HOSTS)
%
%	Parameters:	
%		HOSTS	Multi-string matrix with hostnames to be deleted.
%
%		INFOS	Integer vector returning individual status code for
%			each host:
%			Value		Meaning
%			>=0		?
%			PvmBadParam	bad hostname syntax.
%			PvmSysErr	local pvmd is not responding. ?
%
%		info	Integer scalar returning status code of the routine.
%			Values less than zero indicate an error.
%			Value		Meaning
%			PvmBadParam	giving an invalid argument value.
%			PvmSysErr	local pvmd is not responding.
%
%	Description:
%		If trying to delete the callers hosts, pvm_delhosts returns
%		INFOS=PvmBadParam.
%
%		The PVM documentation of pvm_delhosts's return parameters is
%		not unambigious.
%
%	see also: pvm_hddosts, man pvm_delhosts(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

[info,INFOS]=m2pvm(102,HOSTS);

