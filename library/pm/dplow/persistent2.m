%PERSISTENT2	Managing persistent variables.
%
%	persistent2('open','var_name')
%		restores a variable from the persistent space into the 
%		caller's workspace. If it doesn't exist in the persistent
%		space an empty matrix is created.
%
%	persistent2('close','var_name')
%		saves a variable from the caller's workspace into the 
%		persistent space.
%
%	persistent2('clear')
%		removes all variables from the persistent space.
%
%	persistent2
%		displays persistent space informations including all 
%		contained variables.
%
%	NOTICE:	Currently persistent2 works only with full numeric matrices.
%		You can also save full string matrices, but they must set
%		to string explicitly (with setstr) after any 'open'.

%	Copyright (c) 1998-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta, A. Westphal

% mex implementation: see src/persistent2.c

