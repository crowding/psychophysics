% Distributed and Parallel Toolbox - Low Level PVM Interface.
% Version 1.4
%
% Libpvm Linkage.
%   pvme_link	    - Link libpvm to Matlab.
%   pvme_unlink     - Unink libpvm from Matlab.
%
% PVM Control.
%   pvme_is             - Test whether PVM is running.
%   pvme_default_config - Saves a PVM default configuration.
%   pvme_start_pvmd     - Start new PVM daemon.
%   pvm_addhosts        - Adds hosts to the PVM.
%   pvm_config     - Return information about virtual machine configuration.
%   pvm_mstat      - Return status of specified host in the virtual machine.
%   pvm_delhosts   - Deletes hosts from the PVM.
%   pvme_halt      - Shuts down the entire PVM system excluding the caller.
%
% Setting and Getting Options.
%   pvm_getopt     - Return various libpvm options.
%   pvm_setopt     - Set various libpvm options.
%
% Process Control.
%   pvm_spawn      - Start new PVM process.
%   pvm_export     - Mark environment variables to export through spawn.
%   pvm_unexport   - Unmark environment variables to export through spawn.
%   pvm_kill       - Terminate PVM process.
%   pvm_exit       - Leave PVM.
%
% Information.
%   pvm_mytid      - Return tid of process.
%   pvm_parent     - Return tid of parent process.
%   pvm_pstat      - Return status of specified PVM process.
%   pvm_tasks      - Return info about tasks running on the virt. machine.
%   pvm_tidtohost  - Return host of the specified PVM process.
%   pvm_perror     - Prints error status of last PVM call.
%   pvm_archcode   - Return data representation code for an architecture.
%   pvm_getfds     - Return file descriptors in use.
%   pvm_version    - Return PVM version.
%
% Signaling.
%   pvm_sendsig    - Send signal to PVM process.
%   pvm_notify     - Request notification of PVM event (such as host failure).
%
% Message Buffers.
%   pvm_initsend   - Clear default send buffer and specify message encoding.
%   pvm_mkbuf      - Create a new message buffer and specify message encoding.
%   pvm_getsbuf    - Return message buffer ID for active send buffer.
%   pvm_getrbuf    - Return message buffer ID for active receive buffer.
%   pvm_setsbuf    - Switch active send buffer and save previous buffer.
%   pvm_setrbuf    - Switch active receive buffer and save previous buffer.
%   pvm_bufinfo    - Return information about requested message buffer.
%   pvm_freebuf    - Dispose a message buffer.
%
% Packing / Unpacking Data.
%   pvm_pkdouble   - Pack data of type double into active send buffer.
%   pvm_upkdouble  - Unpack data of type double from active receive buffer.
%   Only with M4:
%    pvme_pkmat         - Pack M4 matrix into active send buffer.
%    pvme_upkmat        - Unpack M4 matrix from active receive buffer.
%    pvme_upkmat_name   - Unpack only matrix name.
%    pvme_upkmat_rest   - Unpack rest of a matrix.
%   Only with M5:
%    pvme_pkarray       - Pack M5 array from active receibe buffer.
%    pvme_upkarray      - Unpack M5 array from active receive buffer.
%    pvme_upkarray_name - Unpack only array name.
%    pvme_upkarray_rest - Unpack rest of array.
%
% Sending and Receiving.
%   pvm_send	- Send data in active message buffer.
%   pvm_mcast	- Multicasts data in active buffer to a set of tasks.
%   pvm_probe	- Check if message has arrived.
%   pvm_recv	- Blocking receive.
%   pvm_trecv	- Timeout receive.
%   pvm_nrecv	- Non-blocking receive.
%
% Group Functions. (z.Z. NICHT ENTHALTEN)
%		- Currently not included.
%
% Master Pvmd Database.
%   pvm_putinfo      - Store message in global mailbox.
%   pvm_recvinfo     - Retrieve message from global mailbox.
%   pvm_getmboxinfo  - Return complete contents of global mailbox.
%		       (Currently not implemented)
%   pvm_delinfo      - Delete message in global mailbox.
%
% Matlab Extensions.
%   persistent2  - Managing persistent variables.
%   putenv	 - Change or add an environment variable.
%   unsetenv	 - Delete an environment variable.
%   selectstdin  - select(2) on stdin 
%		   (Currently no M-Help)
%   Only with M4:
%    strvcat     - Vertically concatenate of strings.
%    strmatch    - Find matches for strings.
%    double      - Convert to double precision.
%    char        - Create character array.
%    filesep	 - Directory separator for this platform. 

% Copyright (c) 1995-1999 University of Rostock, Germany, 
% Institute of Automatic Control. All rights reserved.
% See file ``Copyright'' for terms of copyright.
% Authors: S. Pawletta, M. Suesse, A. Westphal

