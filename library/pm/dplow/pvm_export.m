function info = pvm_export(name)
%PVM_EXPORT
%	Mark environment variables to export through spawn.
%
%	Synopsis:
%		info = pvm_export(name)
%
%	Parameters:
%		name	Name of an environment variable to add
%			to export list.
%		info	No error condition is currently returned.
%
%	The routine pvm_export is provided for convenience in 
%	editing environment variable PVM_EXPORT, while maintaining
%	the colon-separated list syntax it requires.
%
%       pvm_export checks to see if a name is already in PVM_EXPORT
%	before including it, and exporting a name more than once is
%	not considered an error.
%
%	See also: pvm_unexport, pvm_spawn

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info = m2pvm(301,name);

