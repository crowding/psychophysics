function info = pvm_delmhf(mhid)
%PVM_DELMHF		Desinstala función manejadora de mensajes
%
%  info = pvm_delmhf(mhid)
%
%  mhid  (int) identificador PVM del manejador de mensajes a eliminar
%  info  (int) código de retorno
%	0 PvmOk
%      -2 PvmBadParam
%     -32 PvmNotFound
%
%  Implementación MEX quasi-completa: src/pvm_mhf.c, pvm/MEX/pvm_mhf.mexlx

info = pvm_mhf('del', mhid);
