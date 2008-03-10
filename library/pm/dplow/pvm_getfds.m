function [nfds,fds] = pvm_getfds()
%PVM_GETFDS 
%	Returns the file descriptors in use by PVM.
%
%	Synopsis:
%		[fds,nfds] = pvm_getfds
%
%	Parameters:
%		fds	Vector returning the file descriptors.
%
%		nfds	If success, it returns the number of sockets in use,
%			otherwise:
%				PvmSysErr	pvmd not responding.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

[nfds,fds]=m2pvm(409);

