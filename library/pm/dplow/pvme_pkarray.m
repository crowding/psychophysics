function  info = pvme_pkarray(mat,mat_name)
%PVME_PKARRAY
%	Pack MATLAB array into the active message (send) buffer.
%
%	Syntax:
%		info = pvme_pkarray(mat,mat_name)
%
%	Parameters:	
%		mat	 - matrix/array to be packed
%		mat_name - matrix/array name to be packed
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	pvme_pkarray packs mat under the name mat_name into the active message
%	(send) buffer.
% 
%	This function must *NOT* be used in conjunction with PvmDataInPlace 
%	encoding (see pvm_initsend and pvm_mkbuf).
%
%	See also: pvme_upkarray, pvm_initsend, pvm_mkbuf

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta (1995, initial version as pvme_pkmat)
%		 A. Westphal (Nov 98, rewritten for M5 arrays)

info = m2pvm(706,mat,mat_name);

