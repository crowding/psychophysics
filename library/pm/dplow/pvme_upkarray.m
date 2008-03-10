function  [mat,mat_name,info] = pvme_upkarray()
%PVME_UPKARRAY
%	Unpack MATLAB matrix/array from the active message (receive) buffer.
%
%	Synopsis:
%		[mat,mat_name,info] = pvme_upkarray
%
%	Parameters:
%		mat	 - unpacked matrix/array
%		mat_name - unpacked matrix/array name
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	pvme_upkarray unpacks a single matrix/array from the active message 
%	(receive) buffer. The contents of the matrix/array is returned in mat 
%	and the matrix name in mat_name.
%
%	See also: pvme_pkarray

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta (1995, initial version as pvm_upkmat)
%		 A. Westphal (Nov 98, rewritten for M5 arrays)

[mat,mat_name,info] = m2pvm(707);

