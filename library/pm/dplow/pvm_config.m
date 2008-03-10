function [nhost,narch,dtids,hosts,archs,speeds,info]=pvm_config()
%PVM_CONFIG
%	Returns information about the present virtual machine configuration.	
%	
%	Synopsis:
%		[nhost,narch,dtids,hosts,archs,speeds,info]=pvm_config
%
%	Parameters:
%		nhost	Int. scalar returning number of hosts in the PVM.
%		narch	Int. scalar returning number of diff. archs in the PVM.
%		dtids	Int. vector returning all dtids in the PVM.
%		hosts	Multi-string matrix returning all host names in the PVM.
%		archs	Multi-string mat. returning all diff. archs in the PVM.
%		speeds	Integer vector returning speeds of hosts in the PVM.
%
%		info	Integer scalar returning status of the routine. Values
%			less than zero indicate an error:
%			Value		Meaning
%			PvmSysErr	pvmd not responding.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

[info,nhost,narch,dtids,hosts,archs,speeds]=m2pvm(404);


