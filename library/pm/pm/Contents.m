% These are the basic functions of parallel Matlab toolbox:
% 
%PMPARENT   Return the id of the PMI that has spawned the calling process.
%PMPUT      Put a Matlab array on other Matlab process(es)
%PMALL      Return the ID:s of all the PMI:s in the Parallel Matlab System
%PMCLEARBUF Clear the local PM message receive buffer.
%PMMERGEVM  Merge several Virtual Machines.
%PMEVAL     Evaluate a Matlab expression on Matlab instance(s) in the PMS.
%PMEXTERN   Set the PM console to extern mode.
%PMOTHERS   Return all the PMI:s in the PMS except the caller.
%PMGET      Get a Matlab array from another Matlab process
%PMOPEN     Starts a Parallel Matlab System (PMS) session.  
%PMRPC      Remote Remote Call
%PMSPAWN    Start new Parallel Matlab Instance(s).
%PMSEND     Send array.
%PMGETCONF  Return configuration of the current Parallel Matlab System
%PMCANCEL   Send interrupt signal to Matlab process(es)
%PMQUITVM   Leave a VM 
%PMID       Return the id of the calling Matlab process
%PMMEMBVM   List all processes members of a specific Virtual Machine. 
%PMJOINVM   Join a Virtual Machine
%PMRECV     Receive array.
%PMLISTVM   List all VM:s in PMS or the instances of a specific VM.
%PMIS       Test whether there is an open Parallel Matlab System.
%PMSTATE    Display the state of the PVM
%PMCLOSE    Close the Parallel Matlab System.
%PMHOSTNAME Return hostname
%PMKILL     Kill one or several Parallel Matlab processes.
%PMCFG      A GUI for managing the parallel Matlab system.
%PMGETINFO  Return mode and information of a Matlab process.
% 
% There are also the following classes:
% 
%VM         Defines the Virtual Machines
%PMBLOCK    Specifies each dispatched evaluation
%PMRPCFUN   Remote Procedure Call 
%PMFUN      Defines how to do a dispatch
%PMJOB      Permits to vectorise the PMFUN objects.
%



