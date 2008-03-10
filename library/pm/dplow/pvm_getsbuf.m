function bufid=pvm_getsbuf()
%PVM_GETSBUF
%	Returns the message buffer ID for the active send buffer.
%
%	Synopsis:
%		bufid = pvm_getsbuf
%
%	Parameters:
%		bufid	Integer returning message buffer identifier for the 
%			active send buffer or 0 if there is no current buffer.
%			No error conditions are returned.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

bufid=m2pvm(602);



