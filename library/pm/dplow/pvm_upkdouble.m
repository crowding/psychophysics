function [data,info]=pvm_upkdouble(nitem,stride)
%PVM_UPKDOUBLE
%	Unpack double data from the active message (receive) buffer.
%
%	Synopsis:
%		[data,info] = pvm_upkdouble(nitem,stride)
%
%	Parameters:
%		nitem	- total number of elements to be unpacked	
%		stride	- stride to be used when unpacking the elements 	
%
%		data	- returns unpacked data as vector
%		info	- returns status of routine

%       Copyright (c) 1995-1999 University of Rostock, Germany 
%       Institute of Automatic Control. All rights reserved.
%       Authors: M. Suesse, S. Pawletta

[info,data] = m2pvm(703,nitem,stride);

