%PVM_KILL		Termina tarea PVM
%
%  info = pvm_kill(tid)			* tid,info: int/array
%
%  tid	(int/array) tarea PVM (no uno mismo, para eso pvm_exit() mejor)
%                   double ó double array (info saldrá del mismo tamaño)
%  info (int/array) código retorno
%       0 PvmOk
%      -2 PvmBadParam
%     -14 PvmSysErr
%
%  Implementación MEX completa: src/pvm_kill.c, pvm/MEX/pvm_kill.mexlx

