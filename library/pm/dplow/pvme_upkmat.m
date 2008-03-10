function  [mat,mat_name,info] = pvme_upkmat()
%PVME_UPKMAT
%	Unpack MATLAB matrix from the active message (receive) buffer.
%
%	Synopsis:
%		[mat,mat_name,info] = pvme_upkmat
%
%	Parameters:
%		mat	 - unpacked matrix
%		mat_name - unpacked matrix name
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	pvme_upkmat unpacks a single matrix from the active message (receive)
%	buffer. The contents of the matrix is returned in mat and the
%	matrix name in mat_name.
%
%	See also: pvme_pkmat

%	Copyright (c) 1995, 1996 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

[mat,mat_name,info] = m2pvm(152);

