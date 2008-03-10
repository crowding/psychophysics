function bufid=pvm_nrecv(tid,msgtag)
%PVM_NRECV
%	Non-blocking receive.
%	
%	Synopsis:	
%		bufid = pvm_nrecv(tid,msgtag)
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

bufid = m2pvm(808,tid,msgtag);

