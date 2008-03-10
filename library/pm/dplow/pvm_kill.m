function info = pvm_kill(tid)
%PVM_KILL
%	Terminates a specified PVM process.
%	INFO=PVM_KILL(TID) sends a terminate signal to the PVM process
%	identified by TID. If pvm_kill is successful, INFO will be 0. If
%	some error occurs, INFO will be <0.
%
%	PVM_KILL is not designed to kill the calling process. To kill your
%	self call PVM_EXIT followed by QUIT.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info=m2pvm(304,tid);

