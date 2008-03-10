function info = pvm_perror(msg)
%PVM_PERROR
%	Prints the error status of the last PVM call.
%
%	Synopsis:
%		info = pvm_perror(msg)
%
%	Parameters:
%		msg	String supplied by the user which will be prepended 
%			to the error message of the last PVM call.
%
%		info	Integer scalar returning the status of the routine.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

info=m2pvm(407,msg);

