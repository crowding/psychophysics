function  [mat,info] = pvme_upkmat_rest()
%PVME_UPKMAT_REST
%	Unpack the rest of a matrix from the active message (receive) buffer.
%
%	Synopsis:
%		[mat,info] = pvme_upkmat_rest
%
%	Parameters:
%		mat	 - unpacked matrix
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	After pvme_upkmat_name has been called, the rest od a matrix
%	can be unpacked with pvme_upkmat_rest.
%
%	See also: pvme_upkmat pvme_upk_name

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

[mat,info] = m2pvm(154);

