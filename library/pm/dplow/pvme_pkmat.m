function  info = pvme_pkmat(mat,mat_name)
%PVME_PKMAT
%	Pack MATLAB matrix into the active message (send) buffer.
%
%	Syntax:
%		info = pvme_pkmat(mat,mat_name)
%
%	Parameters:	
%		mat	 - matrix to be packed
%		mat_name - matrix name to be packed
%		info	 - status code; 
%			   values less than zero indicate an error
%
%	Description:
%	pvme_pkmat packs mat under the name mat_name into the active message
%	(send) buffer.
% 
%	This function must *NOT* be used in conjunction with PvmDataInPlace 
%	encoding (see pvm_initsend and pvm_mkbuf).
%
%	See also: pvme_upkmat, pvm_initsend, pvm_mkbuf

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info = m2pvm(85,mat,mat_name);

