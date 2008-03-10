%PVM_MCAST		Envía buffer de mensajes activo a varias tareas PVM
%
%  info = pvm_mcast(tids, msgtag)		* tids: int/array
%
%  tids   (int/arr) vector de tids de las tareas PVM a recibir mensaje
%  msgtag (int) código del mensaje >=0
%  info   (int) código de estado
%       0 PvmOk
%      -2 PvmBadParam
%     -14 PvmSysErr
%     -15 PvmNoBuf
%
%  Implementación MEX completa: src/pvm_mcast.c, pvm/MEX/pvm_mcast.mexlx

