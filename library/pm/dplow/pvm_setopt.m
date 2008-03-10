function oldval=pvm_setopt(what,val)
%PVM_SETOPT 
%	Set various libpvm options.
%
%	Synopsis:
%		oldval = pvm_setopt(what,val)
%
%	Parameters:
%		what	Integer scalar defining what to get.
%			Value   	Meaning
%		 	PvmRoute	message routing policy
%		 	PvmDebugMask	libpvm debug mask
%		 	PvmAutoErr	auto error reporting
%		 	PvmOutputTid	stdout destination for children
%		 	PvmOutputCode	output msgtag
%		 	PvmTraceTid	trace data destination for children
%		 	PvmTraceCode	trace msgtag
%		 	PvmFragSize	message fragment size
%		 	PvmResvTids	allow messages to reserved tags and tids
%		 	PvmSelfOutputTid stdout destination
%		 	PvmOutputCode	output msgtag
%		 	PvmSelfTraceTid	trace data destination
%		 	PvmSelfTraceCode trace msgtag
%			PvmShowTids	pvm_catchout prints task ids with output
%			
%		val	Integer scalar specifying new setting for option.
%
%		oldval	Integer scalar returning old option setting. Values
%			less than zero indicate an error:
%			Error:		Possible Cause:
%			PvmBadParam	giving an invalid argument
%
%	Description:
%
%      PvmRoute
%		PvmDontRoute	1 	don't allow direct task-to-task
%    default ->	PvmAllowDirect	2	allow direct links, but don't 
%					request it
%	 	PvmRouteDirect	3	request direct links
%             Advises  PVM  on  whether to set up direct task-to-
%             task links PvmRouteDirect (using TCP) for all  sub-
%             sequent  communication.  Once a link is established
%             it persists until the application finishes.   If  a
%             direct  link  can not be established because one of
%             the two tasks has requested PvmDontRoute or because
%             adequate   resources  aren't  available,  then  the
%             default route through the PVM daemons is used.   On
%             multiprocessors  such  as Intel Paragon this option
%             is ignored because the communication between  tasks
%             on  these  machines always uses the native protocol
%             for direct communication.  pvm_setopt can be called
%             multiple  times  to  selectively  establish  direct
%             links, but is typically  set  only  once  near  the
%             beginning  of  each  task.   PvmAllowDirect  is the
%             default route setting.   This  setting  on  task  A
%             allows  other  tasks  to  set up direct links to A.
%             Once a direct link  is  established  between  tasks
%             both tasks will use it for sending messages.
%
%      PvmDebugMask
%             When  debugging is turned on, PVM will log detailed
%             information about its operations  and  progress  on
%             its  stderr  stream.   val  is the debugging level.
%             Default is not to print any debug information.
%
%      PvmAutoErr
%             When an error results from a libpvm  function  call
%             and  PvmAutoErr is set to 1 (the default), an error
%             message is automatically printed on  stderr.   Set-
%             ting  it  to 0 disables this, while setting it to 2
%             causes the library  to  terminate  the  task  after
%             printing the an error message.
%
%      PvmOutputTid
%             Sets  the  stdout  destination  for  children tasks
%             (spawned after the call to pvm_setopt).  Everything
%             printed  on the standard output of tasks spawned by
%             the calling task is packed into messages  and  sent
%             to  the destination.  val is the TID of a PVM task.
%             Setting PvmOutputTid to 0 redirects stdout  to  the
%             master   pvmd,   which   writes  to  the  log  file
%             /tmp/pvml.<uid> The default  setting  is  inherited
%             from the parent task, else is 0.
%
%      PvmOutputCode
%             Sets  the message tag for standard output messages.
%             Should only be set when a task has PvmOutputTid set
%             to itself.
%
%      PvmTraceTid
%             Sets  the  trace data message destination for chil-
%             dren tasks (spawned after the call to  pvm_setopt).
%             Libpvm trace data is sent as messages to the desti-
%             nation.  val is the TID of  a  PVM  task.   Setting
%             PvmTraceTid  to 0 discards trace data.  The default
%             setting is inherited from the parent task, else  is
%             0.
%
%      PvmTraceCode
%             Sets  the  message  tag  for  trace  data messages.
%             Should only be set when a task has PvmTraceTid  set
%             to itself.
%
%      PvmFragSize
%             Val  specifies  the message fragment size in bytes.
%             Default value varies with host architecture.
%
%      PvmResvTids
%             A val of 1 enables the task to send  messages  with
%             reserved  tags  and  to non-task destinations.  The
%             default (0) causes libpvm to generate a PvmBadParam
%             error when a reserved identifier is specified.
%
%      PvmSelfOutputTid
%             Sets  the  stdout destination for the task.  Every-
%             thing printed on stdout is packed into messages and
%             sent to the destination.  Note: this only works for
%             spawned tasks, because the  pvmd  doesn't  get  the
%             output  from  tasks started by other means.  val is
%             the TID of a PVM task.  Setting PvmSelfOutputTid to
%             0 redirects stdout to the master pvmd, which writes
%             to the log file /tmp/pvml.<uid>.  The default  set-
%             ting  is inherited from the parent task, else is 0.
%             Setting either PvmSelfOutputTid  or  PvmSelfOutput-
%             Code  also  causes both PvmOutputTid and PvmOutput-
%             Code to take on the values of PvmSelfOutputTid  and
%             PvmSelfOutputCode, respectively.
%
%      PvmSelfOutputCode
%             Sets  the message tag for standard output messages.
%
%      PvmSelfTraceTid
%             Sets the trace data  message  destination  for  the
%             task.  Libpvm trace data is sent as messages to the
%             destination.  val is the TID of a PVM  task.   Set-
%             ting PvmSelfTraceTid to 0 discards trace data.  The
%             default setting is inherited from the parent  task,
%             else  is 0.  Setting either PvmSelfTraceTid or Pvm-
%             SelfTraceCode also causes both PvmTraceTid and Pvm-
%             TraceCode  to take on the values of PvmSelfTraceTid
%             and PvmSelfTraceCode, respectively.
%
%      PvmSelfTraceCode
%             Sets the message tag for trace data messages.
%
%      PvmShowTids
%             If true (nonzero), pvm_catchout tags each  line  of
%             output  printed  by  a child task with the task id.
%             Otherwise, output is exactly as printed.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: M. Suesse, S. Pawletta

oldval=m2pvm(201,what,val);

