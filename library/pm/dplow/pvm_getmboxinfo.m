function [info,nclasses,names,nentries,indices,owners,flags]=pvm_getmboxinfo(pattern)
%PVM_GETMBOXINFO
%	Return complete or partial contents of global mailbox.
%	
%	Synopsis:
%   [info,nclasses,names,nentries,indices,owners,flags]=pvm_getmboxinfo(pattern)
%
%	Input Parameters:
%		pattern	GNU regular expression (pattern) to match on  names
%			in  mailbox  database.   Additionally, the singular
%			'*' will match on all names.
%
%	Output Parameter:
%		nclasses Number of classes matching pattern.
%
%		names	Multi-string matrix containing the names of 
%			matching classes.
%
%		nentries Vector containing the number of entries for 
%			each matching class.
%
%		indices	Matrix containing the indices of each matching
%			class (columnwise). 
%
%		owner	Matrix containing the task ids that inserted entry 
%			into mailbox database (columnwise).
%
%		flags   Matrix containing the the flags (columnwise).
%
%		info	Resulting status code:
%
%			PvmNotFound (-32)
%			No class matches pattern.
%
%			PvmSysErr (-14)
%			Can't contact local daemon.
%
%	pvm_getmboxinfo  returns  complete informations for all
%	classes in the dadabase matching pattern.
%
%	See also: pvm_putinfo, pvm_recvinfo, pvm_delinfo

%       Copyright (c) 1998-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%       Author: S. Pawletta (Nov 98, initial version)
%               E. Svahn Nov 2000. C-code reviewed and now working.

[info,nclasses,names,nentries,indices,owners,flags]=m2pvm(904,pattern);




