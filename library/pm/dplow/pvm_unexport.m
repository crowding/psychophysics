function info = pvm_unexport(name)
%PVM_UNEXPORT
%	Unmark environment variable to export through spawn.
%
%	Synopsis:
%		info = pvm_unexport(name)
%
%	Parameters:
%		name	Name of an environment variable to delete
%			from export list.
%		info	No error condition is currently returned.
%
%	The routine pvm_unexport is provided for convenience in 
%	editing environment variable PVM_EXPORT, while maintaining
%	the colon-separated list syntax it requires.
%
%       pvm_unexport will not complain if you specify a name not
%	in PVM_EXPORT.
%
%	See also: pvm_export, pvm_spawn

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info = m2pvm(302,name);

