function info=pvm_notify(what,msgtag,cnt,tids)
%PVM_NOTIFY
%	Request notification of PVM event such as host failure.
%	
%	Synopsis:
%		info = pvm_notify(what,msgtag,cnt,tids)
%
%	Parameters:
%		what	Integer scalar containing the type of event to trigger
%			the notification. Presently one of:
%			Value   	Meaning
%		 	PvmTaskExit	notify if task exits
%			PvmHostDelete	notify if host is deleted
%			PvmHostAdd	notify if host is added
%		msgtag	rMmessage tag to be used in notification
%		cnt	Length of tids array for PvmTaskExit and PvmHostDelete.
%			Numbers of times to notify for PvmHostAdd.
%		tids	Vector with cnt elements containing task or pvmd tids 
%			to be notified. For PvmHostAddi, this argument is
%			ignored.
%
%		info	Integer scalar returning the status of the routine.
%			Values less than zero indicate an error:
%			Value		Meaning
%			PvmSysErr	pvmd not responding.
%			PvmBadParam	giving an invalid argument value.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse

info=m2pvm(501,what,msgtag,cnt,tids);

