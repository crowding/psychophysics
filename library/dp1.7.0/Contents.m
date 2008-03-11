% DP-Toolbox 1.7.0
% Distributed and parallel application toolbox
%
% University of Wismar, Department Department of Electrical Engineering
% University of Wismar, Department of Mechanical Engineering
% University of Rostock, Institute of Automatic Control
%
% Authors: S.Pawletta, R.Fink, T.Pawletta, P.Duenow, W.Drewelow, A.Westphal
%
% Copyright (C) 1995-2004 All rights reserved.
%
%
% User interface commands (see help pages for description):
%   dpmyid - get current task id
%   dpparent - get parent task id
%   dpexit - disconnect from DP subsystem (PVM)
%   dpkill - kill DP task
%   dpsend - send data to task
%   dprecv - receive data from task
%   dpspawn - spawn new tasks
%   dpscatter - scatters a matrix among tasks
%   dpgather - gathers a matrix from tasks
%
% Demo scripts (see help pages for description):
%   dp_demo1 - one task send/receive demo
%   dp_demo2 - three task spawn/send/receive demo
%   dp_demo3 - three task spawn/scatter/gather demo
%
% Test applications (see help pages for description):
%   dp_sendtest - tests sending/receiving of several MATLAB data types
%   dp_scattertest - tests scatter/gather operations
%
% Internal commands (see help pages for description):
%   dp_internal_pack - pack data into PVM send buffer
%   dp_internal_unpack - unpack data from PVM receive buffer
%   dp_internal_scatter - split up a matrix
%   dp_internal_gather - concatenate a matrix
%
% Low level commands (see PVM man pages for description):
%   pvm_mytid - get PVM task id
%   pvm_parent - get PVM parent task id
%   pvm_exit - exit from local pvmd
%   pvm_kill - kill PVM task
%   pvm_send - send message to PVM task
%   pvm_recv - receive message from PVM tak
%   pvm_spawn - spawn PVM task
%   pvm_initsend - initialize PVM send buffer
%   pvm_pkbyte - pack array of bytes into PVM send buffer
%   pvm_upkbyte - unpack array of bytes from PVM receive buffer
%   pvm_pkint - pack array of integers into PVM send buffer
%   pvm_upkint - unpack array of integers from PVM receive buffer
%   pvm_pkdouble - pack array of double values into PVM send buffer
%   pvm_upkdouble - unpack array of double values from PVM receive buffer
%
% Mex commands:
%   m2pvm - MEX library for pvm wrapper functions

