function  [mat,info] = pvme_upkarray_rest()
%PVME_UPKARRAY_REST
%	Unpack the rest of a matrix/array from the active message (receive) 
%	buffer.
%
%	Synopsis:
%		[mat,info] = pvme_upkarray_rest
%
%	Parameters:
%		mat	 - unpacked matrix/array
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	After pvme_upkarray_name has been called, the rest of an array
%	can be unpacked with pvme_upkarray_rest.
%
%	See also: pvme_upkarray pvme_upkarray_name

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta (1995, initial version as pvm_upkmat_body)
%		 A. Westphal (Nov 98, rewritten for M5 arrays)
%                E. Svahn (Nov 2000, rewritten temporarily for transfer
%                   of user defined objects)
  
[mat,info] = m2pvm(709);
if info == 1,
  load(mat);
  delete(mat);
  mat = objsl;
  info = 0;
end

