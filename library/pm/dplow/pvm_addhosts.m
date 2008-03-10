function [INFOS,info] = pvm_addhosts(HOSTS)
%PVM_ADDHOSTS
%	Adds one or more hosts to the virtual machine.
%
%	Synopsis:
%		[INFOS,info] = pvm_addhosts(HOSTS)
%
%	Parameters:	
%		HOSTS	Multi-string matrix with hostnames (plus configuration
%			options s. man pvmd3(3PVM)) to be added. On most systems
%			numeric Ip-addresses are not supported).
%
%		INFOS	Integer vector returning individual status code for
%			each host:
%			Value		Meaning
%			>0		dtid (tid of local pvmd3) of the host.
%			PvmBadParam	bad hostname syntax.
%			PvmNoHost	no such host.
%			PvmCantStart	failed to start pvmd on host.
%			PvmDupHost	host already configured.
%			PvmBadVersion	remote pvmd version doesn't match.
%			PvmOutOfRes	PVM has run out of system resources.
%
%		info	Integer scalar returning status code of the routine.
%			Values less than zero indicate an error.
%			Value		Meaning
%			>0		number of successful additions
%			PvmBadParameter	giving an invalid argument value.
%			PvmAlready	already been added.
%			PvmSysErr	local pvmd is not responding.
%
%	Description:
%		It is not possible to startup a PVM by calling 
%		pvm_addhosts('initial-host'). pvm_addhost can only
%		extend an already running PVM.
%
%	see also: pvm_delhosts, man pvm_addhosts(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

[info,INFOS]=m2pvm(101,HOSTS);

