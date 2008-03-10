function info = pvme_halt()
%PVME_HALT
%	Shuts down the entire PVM system excluding the caller.
%	
%	Syntax:
%		info = pvme_halt
%
%	Parameters:
%		info		returns status of the routine. Values less
%				than zero indicates an error.
%		   		Error Value	Possible cause
%				PvmSysErr	Local pvmd is not responding.
%
%	See also: man pvm_halt(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta, M. Suesse

info=m2pvm(104);

