function info=pvm_catchout(stream)
%PVM_CATCHOUT
%	Catch output from child tasks.
%	
%	Synopsis:
%		info = pvm_catchout(stream)
%		info = pvm_catchout()
%
%	Parameters:
%      		stream	Pointer to a file, stdout or stderr (see pvm_fopen,
%			Matlab's file I/O functions do not work in this
%			context) on which to write collected output.
%			
%			Without any parameter, pvm_catchout turns output 
%			collection off.
%
%      		info    Integer scalar returning the status code of the 
%			routine. Values less than zero indicate an error.
%
%			Without an input parameter, pvm_catchout returns
%			always zero.
%
%	Description:
%
%      The routine pvm_catchout causes the calling task (the par-
%      ent)  to catch output from tasks spawned after the call to
%      pvm_catchout.  Characters printed on stdout or  stderr  in
%      children tasks are collected by the pvmds and sent in con-
%      trol messages to the parent task, which tags each line and
%      appends  it to the specified file.  Output from grandchil-
%      dren (spawned by children) tasks is also  collected,  pro-
%      vided the children don't reset PvmOutputTid.
%
%      If  option PvmShowTids (see pvm_setopt) is true (nonzero),
%      output is printed as shown below, tagged with the task  id
%      where the output originated:
%           [txxxxx] BEGIN
%           [txxxxx] (text from child task)
%           [txxxxx] END
%
%      The  output from each task includes one BEGIN line and one
%      END line, with whatever the task prints  in  between.   If
%      PvmShowTids  is false, raw output is printed with no addi-
%      tional information.
%
%      If  pvm_exit  is  called  while  output  collection  is in
%      effect, it will block until all tasks  sending  it  output
%      have exited, in order to print all their output.  To avoid
%      this, output collection  can  be  turned  off  by  calling
%      pvm_catchout() before calling pvm_exit.
%
%      Example:
%		stdout=pvm_fopen('stdout');
%
%		pvm_catchout(stdout);
%
%		pvm_spawn('any_exec_o','',PvmTaskDefault,'',1);
%
%		... child output appears on stdout ...
%
%		pvm_catchout		% turn off collecting
%
%
%	See also: pvm_fopen, pvm_setopt, man pvm_catchout(3PVM)

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Authors: S. Pawletta

if nargin == 0
	info=m2pvm(303);
else
	info=m2pvm(303,stream);
end



