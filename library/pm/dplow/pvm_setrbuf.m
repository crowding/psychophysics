function oldbuf=pvm_setrbuf(bufid)
%PVM_SETRBUF 
%	Switches the active receive buffer and saves the previous buffer.
%	
%	Synopsis:
%		oldbuf = pvm_setrbuf(bufid)
%
%	Parameters:
%		bufid	Integer specifying the message buffer identifier for 
%			the new active receive buffer. If bufid is set to 0
%			then the present active receive buffer is saved and
%			no active receive buffer exists.
%
%		oldbuf	Integer returning the message buffer identifier for 
%			previous active receive buffer. These error conditions
%			can be returned:
%			Error value	Possible cause
%			PvmBadParam	giving an invalid bufid.
%			PvmNoSuchBuf	switching to a non-existent
%					message buffer.
%
%	See also: man pvm_setrbuf(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

oldbuf=m2pvm(605,bufid);

