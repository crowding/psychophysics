function info=pvm_send(tid,msgtag)
%PVM_SEND
%	Sends the data in the active message buffer.
%	
%	Synopsis:
%		info = pvm_send(tid,msgtag)
%
%	Parameters:
%		tid	Integer task identifier of destination process.
%		msgtag	Integer message tag supplied by the user. Should
%			be >=0 .
%
%		info 	Status code. Values less than zero indicate an error.
%			Error value	Possible cause
%			PvmBadParam	giving an invalid tid or msgtag
%			PvmSysErr	pvmd not responding
%			PvmNoBuf	no active send buffer 

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

info = m2pvm(800,tid,msgtag);

