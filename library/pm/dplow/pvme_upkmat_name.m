function  [mat_name,info] = pvme_upkmat_name()
%PVME_UPKMAT_NAME
%	Unpack matrix name from the active message (receive) buffer.
%
%	Synopsis:
%		[mat_name,info] = pvme_upkmat_name
%
%	Parameters:
%		mat_name - unpacked matrix name
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	pvme_upkmat_name unpacks only the name of a matrix from the active 
%	message (receive) buffer. The rest of the matrix leaves in the buffer
%	and can be unpacked later.
%
%	See also: pvme_upkmat, pvme_upkmat_rest

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

[mat_name,info] = m2pvm(153);

