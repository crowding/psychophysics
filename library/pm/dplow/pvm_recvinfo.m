function bufid=pvm_recvinfo(name,index,flags)
%PVM_RECVINFO
%	Retrieve message from global mailbox.
%	
%	Synopsis:
%		bufid = pvm_recvinfo(name,index,flags)
%
%	Input Parameters:
%		name	Database key (class name), any single string.
%
%		index   Database key (class index >=0). Default index=0.
%
%		flags   Any sum of the following options:
%
%			PvmMboxDefault (0)
%			Exact match on key <name,index> is requested.
%
%			PvmMboxFirstAvail (8)
%			The  first  entry in <name> with index greater than
%			or  equal  to  the  specified  index  parameter  is
%			requested. PvmMboxFirstAvail  with  index  = 0 will
%			produce the same results as using PvmMboxDefault.
%
%			PvmMboxReadAndDelete (16)
%			Return entry and delete from database.   Task  must
%			be  permitted  to do both read and delete otherwise
%			an error will occur.
%
%	Output Parameter:
%		bufid   Handle of message buffer containing the requested
%			record from database or one of the following error 
%			codes:
%
%			PvmNotFound (-32)
%			The requested key does not exist.
%
%			PvmDenied (-8)
%			The key is locked by another task and cannot be
%			deleted (could occur with PvmMboxReadAndDelete).
%
%			PvmSysErr (-14)
%			Can't contact local daemon.
%
%	pvm_recvinfo operates just like a  pvm_recv()  except  the
%	message  is  coming from the database.  The message should
%	be  unpacked   after   pvm_recvinfo().    Like   pvm_recv,
%	pvm_recvinfo  returns  a  handle  to a message buffer con-
%	taining the record matching the key <name,index> from  the
%	database.
%
%	See also: pvm_putinfo, pvm_getmboxinfo, pvm_delinfo

%       Copyright (c) 1995-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%       Author: S. Pawletta (1995, initial version with pvm_lookfor, PVM 3.3)
%		            (Nov 98, rearranged to pvm_recvinfo, PVM 3.4)

bufid = m2pvm(902,name,index,flags);

