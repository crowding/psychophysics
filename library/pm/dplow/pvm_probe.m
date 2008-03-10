function bufid=pvm_probe(tid,msgtag)
%PVM_PROBE
%	Check if messages has arrivied.
%	
%	Synopsis:
%		bufid = pvm_probe(tid,msgtag)
%
%	Parameters:
%		tid	- tid of sending process supplied by the user
%			  (-1 matches any tid)
%		msgtag	- message tag supplied by the user
%			  (-1 matches any message tag)
%
%		bufid	- returns new active receive buffer

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: M. Suesse, S. Pawletta

bufid =  m2pvm(807,tid,msgtag);

