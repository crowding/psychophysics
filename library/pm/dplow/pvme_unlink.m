function pvme_unlink()
%PVME_UNLINK
%	Unlinks the Libpvm from Matlab.
%
%	pvme_unlink should be called as the very last function of 
%	a Matlab/PVM session.
%
%	See also: pvme_link

%	Copyright (c) 1998-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info = m2pvm(1303);

if info == 0
	clear m2pvm
end

