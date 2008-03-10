function oldbuf=pvm_setsbuf(bufid)
%PVM_SETSBUF 
%	Switches the active send buffer and saves the previous buffer.
%	
%	Synopsis:
%		oldbuf = pvm_setsbuf(bufid)
%
%	Parameters:
%		bufid	Integer specifying the message buffer identifier for 
%			the new active send buffer. If bufid is set to 0 then
%			the present active buffer is saved and no active send
%			buffer exists.
%
%		oldbuf	Integer returning the message buffer identifier for 
%			the previous active send buffer. These error conditions
%			can be returned:
%			Error value	Possible cause
%			PvmBadParam	giving an invalid bufid.
%			PvmNoSuchBuf	switching to a non-existent
%					message buffer.
%
%	See also: man pvm_setsbuf(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

oldbuf=m2pvm(604,bufid);

