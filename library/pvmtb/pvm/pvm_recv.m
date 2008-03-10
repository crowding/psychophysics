%PVM_RECV		Recibe un mensaje, crea buffer recepción. Bloqueante.
%
%  bufid = pvm_recv(tid, msgtag)		* tid, bufid: int
%
%  tid    (int) identificador de la tarea que envía. -1 para cualquiera
%  msgtag (int) código del mensaje >=0. -1 para cualquiera
%  bufid  (int) <0 código de estado
%      >0 nuevo buffer recepción
%      -2 PvmBadParam
%     -14 PvmSysErr
%
%  Implementación MEX completa: src/pvm_recv.c, pvm/MEX/pvm_recv.mexlx

