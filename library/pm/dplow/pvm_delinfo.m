function info=pvm_delinfo(name,index,flags)
%PVM_DELINFO
%	Delete message in global mailbox.
%	
%	Synopsis:
%		info = pvm_delinfo(name,index,flags)
%
%	Input Parameters:
%		name	Database key (class name), any single string.
%
%		index   Database key (class index >=0). Default index=0.
%
%		flags   There are no flags presently specified for pvm_delinfo.
%			(any value given for flags is ignored)
%
%	Output Parameter:
%		info	Resulting status code:
%
%			PvmOk (0)
%			Success.
%
%			PvmNotFound (-32)
%			Key does not exist.
%
%			PvmDenied (-8)
%			Key is locked by another task and cannot be
%			deleted.
%
%			PvmSysErr (-14)
%			Can't contact local daemon.
%
%	pvm_delinfo deletes database entry specified  by  the  key
%	<name,  index>.
%
%	See also: pvm_putinfo, pvm_recvinfo, pvm_getmboxinfo

%       Copyright (c) 1995-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%       Author: S. Pawletta (1995, initial version with pvm_delete, PVM 3.3)
%		            (Nov 98, rearranged to pvm_delinfo, PVM 3.4)

info=m2pvm(903,name,index,flags);

