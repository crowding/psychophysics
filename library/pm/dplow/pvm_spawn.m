function [tids,numt] = pvm_spawn(task,ARGV,flag,where,ntask)
%PVM_SPAWN
%	Start new PVM processes.
%	
%	Synopsis:
%		[tids,numt] = pvm_spawn(task,ARGV,flag,where,ntask)
%
%	Input parameters:
%      		task    String matrix which contains the executable file name
%              		of the PVM process to be started.  The  executable
%              		must  already reside on the host on which it is to
%              		be started.  The name may be a  file  in  the  PVM
%              		search  path or an absolute path.  The default PVM
%              		search path is $HOME/pvm3/bin/$PVM_ARCH/ and can be
%			extended by the ep-option in the hostfile or pvm_
%			addhosts.
%
%      		ARGV    Multi-string matrix of arguments to the executable
%              		(if  supported on the target machine), not includ-
%              		ing the executable name. argv[0] of the spawned task 
%			is set to the executable path relative to the  PVM
%              		working  directory  (or  absolute  if  an absolute
%              		filename was specified).  If the executable  needs
%              		no   arguments,   then   the  matrix is empty.
%
%      		flag    Integer scalar specifying spawn options. The flag 
%			should be the sum of:
%                   	Option value        MEANING
%                   	PvmTaskDefault 0    PVM can choose any machine to 
%					    start task
%                   	PvmTaskHost    1    where specifies a particular host
%                   	PvmTaskArch    2    where specifies a type of archi-
%					    tecture
%                   	PvmTaskDebug   4    Start up processes under debugger
%                   	PvmTaskTrace * 8    Processes will generate PVM trace 
%					    data.
%                   	PvmMppFront    16   Start process on MPP front-end.
%                   	PvmHostCompl   32   Use complement host set
%
%              		* means future extension
%
%      		where   String matrix specifying where to start the PVM
%              		process.   Depending  on  the value of flag, where
%              		can be a host name such  as  'ibm1.epm.ornl.gov' or 
%			'.' for the local host or a PVM architecture class 
%			such as 'SUN4'. If flag is 0,then where is ignored 
%			and PVM will select the most appropriate host.
%
%      		ntask   Integer scaler specifying the number of copies of 
%			the executable to start.
%
%	  Output parameters:
%      		tids    Vector with ntask elements returning  the  tids
%              		of  the  PVM  processes  started by this pvm_spawn
%              		call.
%	
%      		numt    Integer scalar returning the actual number of tasks
%              		started.   Values less than zero indicate a system
%              		error.  A positive value less than ntask indicates
%              		a  partial  failure.  In this case the user should
%              		check the tids array for the error code(s).
%      			These error conditions can be returned by pvm_spawn 
%			either in numt or in the tids array:
%
%      			PvmBadParam
%             			giving an invalid argument value.
%
%      			PvmNoHost
%             			Specified host is not in the virtual machine.
%
%      			PvmNoFile
%             			Specified  executable  cannot be found. The 
%				default location PVM looks  in  is  
%				~/pvm3/bin/ARCH,  where ARCH is a PVM archi-
%				tecture name.
%
%      			PvmNoMem
%             			Malloc failed. Not enough memory on host.
%		
%      			PvmSysErr
%             			pvmd not responding.
%
%      			PvmOutOfRes
%             			out of resources.

%	Copyright (c) 1995-1999 University of Rostock, Germany, 
%	Institute of Automatic Control. All rights reserved.
%	Author: S. Pawletta

[numt,tids] = m2pvm(300,task,ARGV,flag,where,ntask);

