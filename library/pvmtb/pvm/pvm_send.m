%PVM_SEND		Envía los datos del buffer de mensajes activo
%
%  info = pvm_send(tid, msgtag)			* tid, info: int
%
%  tid    (int) identificador de la tarea a la que se manda el mensaje
%  msgtag (int) código del mensaje >=0
%  info   (int) código de estado
%       0 PvmOk
%      -2 PvmBadParam
%     -14 PvmSysErr
%     -15 PvmNoBuf
%
%  Implementación MEX completa: src/pvm_send.c, pvm/MEX/pvm_send.mexlx

