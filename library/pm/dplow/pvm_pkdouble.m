function info=pvm_pkdouble(data,nitem,stride)
%PVM_PKDOUBLE
%	Pack double data into the active message (send) buffer.
%
%	Synopsis:
%		info = pvm_pkdouble(data,nitem,stride)
%
%	Parameters:	
%		data	Matrix from which the real part is packed as double
%			array in the sense of data(:) .
%		nitem	Total number of elements to be packed.
%		stride	Stride to be used when packing the elements.
% 
%		info	returns status of routine.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse

info = m2pvm(700,data,nitem,stride);

