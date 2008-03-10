function info = pvm_exit()
%PVM_EXIT
%	Tells the local pvmd that this process leaving PVM.
%	INFO=PVM_EXIT returns a status code. Values less than zero indicate
%	an error.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

info=m2pvm(305);

