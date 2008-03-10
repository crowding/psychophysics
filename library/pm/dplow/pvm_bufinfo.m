function [bytes,msgtag,tid,info]=pvm_bufinfo(bufid)
%PVM_BUFINFO
%	Returns information about the requested message buffer
%
%	Synopsis:	
%		[bytes,msgtag,tid,info]=pvm_bufinfo(bufid)
%
%	Parameters:
%		bufid	- specified message buffer ID
%		bytes	- returns message length in bytes
%		msgtag	- returns message label
%		tid	- returns message source
%		info	- returns status of routine

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

[info,bytes,msgtag,tid]=m2pvm(606,bufid);


