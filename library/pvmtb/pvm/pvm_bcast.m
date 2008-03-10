%PVM_BCAST		Envía buffer de mensajes activo a instancias grupo
%
%  info = pvm_bcast('group', msgtag)	* info, msgtag: int/array por comodidad
%
%  group (string) nombre del grupo
%  msgtag   (int) código del mensaje >=0
%  info  (int)    código de retorno
%       0 PvmOk
%     -14 PvmSysErr
%      -2 PvmBadParam
%     -19 PvmNoGroup
%				info, msgtag pueden ser arrays por comodidad de
%			implementación (igual que pvm_getinst, pvm_gettid)
%
%  Implementación MEX completa: src/pvm_bcast.c, pvm/MEX/pvm_bcast.mexlx

