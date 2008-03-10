function bufid=pvm_getrbuf()
%PVM_GETRBUF
%	Returns the message buffer ID for the active receive buffer.
%
%	Synopsis:
%		bufid = pvm_getrbuf
%
%	Parameters:
%		bufid	Integer returning message buffer identifier for the
%			active receive buffer or 0 if there is no current
%			buffer. No error conditions are returned.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

bufid=m2pvm(603);



