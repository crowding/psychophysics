function info=pvm_freebuf(bufid)
%PVM_FREEBUF
%	Disposes a message buffer.
%	
%	Synopsis:
%		info = pvm_freebuf(bufid)
%
%	Parameters:
%		bufid	Integer message buffer identifier.
%		info	Integer status code returned by the routine.
%			Values less than zero indicate an error.
%			Error Value	Possible Cause
%			PvmBadParam	giving an invalid argument value.
%			PvmNoSuchBuf	giving an invalid bufid value.
%
%	See also: man pvm_freebuf(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

info=m2pvm(607,bufid);



