function [ntask,tids,ptids,dtids,states,tasks,info]=pvm_tasks(which)
%PVM_TASKS
%	Returns information about the tasks running on the virtual machine.
%	
%	Synopsis:
%		[ntask,tids,ptids,dtids,states,tasks,info]=pvm_tasks(which)
%	
%	Parameters:
%		which	Integer scalar specifying what tasks to return infor-
%			mation about. The options are:
%				0	for all the tasks on the virtual machine
%				dtid	for all tasks on a given host
%				tid	for a specific task
%		
%		ntask	Integer scalar returning the number of tasks being
%			reported on.
%		tids	returning task identifier(s).
%		ptids	returning identifier(s) of parent(s).
%		dtids	returning pvmd identifier(s).
%		states	returning status of task(s).
%		tasks	Multi-string matrix with name(s) of spawned task(s).
%			Manualy started tasks return blanks.
%
%		info	Integer scalar returning status of the routine. Values 
%			less than zero indicate an error:
%			Value		Meaning
%			PvmBadParam	invalid value for which argument.
%			PvmSysErr	pvmd not responding.
%			PvmNoHost	specified host not in the virt. machine.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

[info,ntask,tids,ptids,dtids,states,tasks]=m2pvm(405,which);


