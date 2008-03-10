%PVM_PSEND		Empaqueta/envía arraydouble en una sola llamada PVM
%
%  [info len] = pvm_psend(tid, msgtag, data)
%
%  tid    (int) identificador de la tarea a la que se manda el mensaje
%  msgtag (int) código del mensaje >=0
%  data(double) array a empaquetar y enviar
%
%  len    (int) longitud a usar en el respectivo pvm_precv
%  info   (int) código de estado
%       0 PvmOk
%      -2 PvmBadParam
%     -14 PvmSysErr
%
%  Implementación MEX completa: src/pvm_psend.c, pvm/MEX/pvm_psend.mexlx

