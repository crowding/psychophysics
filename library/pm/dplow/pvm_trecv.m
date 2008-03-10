function bufid=pvm_trecv(tid,msgtag,sec,usec)
%PVM_TRECV
%	Timeout receive.
%	
%	Synopsis:	
%		bufid = pvm_trecv(tid,msgtag,sec,usec)
%
%	Parameters:
%		tid	- tid of sending process supplied by the user
%			  (-1 matches any tid)
%		msgtag	- message tag supplied by the user
%			  (-1 matches any message tag)
%		sec,	- time to wait before returning without
%		usec	  a message.
%
%		bufid	- returns new active receive buffer ID 

%	Copyright (c) 1998-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

bufid = m2pvm(809,tid,msgtag,sec,usec);

