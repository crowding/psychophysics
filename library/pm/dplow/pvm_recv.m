function bufid=pvm_recv(tid,msgtag)
%PVM_RECV
%	Receive a message (blocking).
%	
%	Synopsis:	
%		bufid = pvm_recv(tid,msgtag)
%
%	Parameters:
%		tid	- tid of sending process supplied by the user
%			  (-1 matches any tid)
%		msgtag	- message tag supplied by the user
%			  (-1 matches any message tag)
%
%		bufid	- returns new active receive buffer ID 

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

bufid = m2pvm(801,tid,msgtag);

