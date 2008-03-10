function index=pvm_putinfo(name,bufid,flags)
%PVM_PUTINFO
%	Store message in global mailbox.
%	
%	Synopsis:
%		index = pvm_putinfo(name,bufid,flags)
%
%	Input Parameters:
%		name	Database key (class name), any single string.
%
%		bufid   Handle of message buffer to put in database.
%
%		flags   Any sum of the following options:
%
%			PvmMboxDefault (0)
%			Inserts entry as the only named instance for a given
%			name. This entry may only be modified and deleted by
%			its owner. It is automatically deleted when its owner 
%			exits.
%
%			PvmMboxPersistent (1)
%			Entry remains in the database when the owner task 
%			exits. Entries are removed from the database when PVM
%			is halted or a reset is issued from the console.
%
%			PvmMboxMultiInstance (2)
%			Permits multiple entry instances of the same name.
%			PVM will assign an index key to each instance.
%
%			PvmMboxOverWritable (4)
%			Permits other tasks to overwrite and delete this
%			database entry.
%
%	Output Parameter:
%		index   Database key (class index >=0) of the record if it 
%			has been successfully stored or one of the following
%			error codes:
%
%			PvmBadParam (-2)
%			An invalid value was specified for bufid argument.
%
%			PvmNoSuchBuf (-16)
%			Message buffer bufid doesn't exist.
%
%			PvmNoMem (-10)
%			Libpvm is unable to allocate memory to pack data.
%
%			PvmExists (-33)
%			The requested key is already in use.
%
%			PvmDenied (-8)
%			The key is locked by another task and cannot be
%			replaced.
%
%			PvmSysErr (-14)
%			Can't contact local daemon.
%
%	A "message mailbox" database can  be used  by PVM tasks to 
%	advertise information to other PVM tasks.
%	
%	The  database  entries  are  PVM  messages keyed by a user
%	specified name and an optional index value.  The name  may
%	be  an  arbritary string  and  the  index  a  non-negative 
%	integer.  The index value is assigned by PVM and  is  used
%	to  uniquely  identify  one  of  multiple  named instances
%	within the database.
%	
%	Entries are "owned" by the task  that  created  them.   An
%	entry  is automatically removed from the database when the
%	owner task exits unless the  database  entry  was  created
%	with flag PvmMboxPersistent.
%	
%	When  a task exits and leaves an entry in the mailbox, the
%	owner tid of that entry is marked as zero (0) to  indicate
%	that there is no longer an active owner task.
%	
%	pvm_putinfo  inserts a record in the database, given a key
%	and data (message).  It returns mailbox  index  number  if
%	the  record  is successfully stored, PvmExists if a record
%	with the given key already  exists,  or  PvmDenied  if  an
%	attempt is made to overwrite a locked  record (or  another
%	error, see list above).
%
%	See also: pvm_recvinfo, pvm_getmboxinfo, pvm_delinfo

%       Copyright (c) 1995-1999 University of Rostock, Germany,
%	Institute of Automatic Control. All rights reserved.
%       Author: S. Pawletta (1995, initial version with pvm_insert, PVM 3.3)
%		            (Nov 98, rearranged to pvm_putinfo, PVM 3.4)

index=m2pvm(901,name,bufid,flags);

