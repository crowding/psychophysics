%PVM_TICKLE		Diversos volcados de información y configuración
%
%  [info resp]= pvm_tickle(args)
%
%  args (int/intarr)	1 entero   how		(how == 0..5 , 100) ó
%			2 enteros [how arg]	(how == 6..9)
%	arg (int) valor deseado para la opción how (para how > 5)
%	how (int) volcado deseado (100,0..5) ú opción a ajustar (6..9)
%		tabla tomada del "help tickle" en PVM console
%	100   dump shared memory data structures
%	  0   dump heap
%	  1   dump host table
%	  2   dump local task table
%	  3   dump waitc list
%	  4   dump message mailbox
%	  5   get debugmask
%	  6   (mask) set debugmask
%	        mask is the sum of the following bits for information about
%	           1  Packet routing
%	           2  Message routing and entry points
%	           4  Task state
%	           8  Slave pvmd startup
%	          16  Host table updates
%	          32  Select loop
%	          64  IP network
%	         128  Multiprocessor nodes
%	         256  Resource manager interface
%	         512  Application warnings (scrapped messages etc.)
%	        1024  Wait contexts
%	        2048  Shared memory operations
%	        4096  Semaphores
%	        8192  Locks
%	  7   (num) set nopax
%	  8   (dtid) trigger hostfail
%	  9   (rst) dump pvmd statistics, clear if rst true
%
%  resp (intarr) volcado solicitado
%  info (int)    código de retorno
%        0 PvmOk
%      -14 PvmSysErr
%
%  Implementación MEX completa: src/pvm_tickle.c, pvm/MEX/pvm_tickle.mexlx

