function  [mat_name,info] = pvme_upkarray_name()
%PVME_UPKARRAY_NAME
%	Unpack matrix/array name from the active message (receive) buffer.
%
%	Synopsis:
%		[mat_name,info] = pvme_upkarray_name
%
%	Parameters:
%		mat_name - unpacked matrix/array name
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	pvme_upkarray_name unpacks only the name of a matrix/array from the 
%	active message (receive) buffer. The rest of the matrix/array leaves 
%	in the buffer and can be unpacked later.
%
%	See also: pvme_upkarray, pvme_upkarray_rest

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta (1995, initial version as pvm_pkmat_head)
%		 A. Westphal (Nov 98, rewritten for M5 arrays)

[mat_name,info] = m2pvm(708);

