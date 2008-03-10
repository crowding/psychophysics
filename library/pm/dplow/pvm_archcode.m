function code = pvm_archcode(arch)
%PVM_ARCHCODE 
%	Returns the data representation code for a PVM architecture name.
%
%	Synopsis:
%		code = pvm_archcode(arch)
%
%	Parameters:
%		arch	String containing the architecture name.
%
%		code	Integer Scalar returning the architecture code.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

code=m2pvm(408,arch);

