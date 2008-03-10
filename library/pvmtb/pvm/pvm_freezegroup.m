%PVM_FREEZEGROUP	Congela pertenencia dinámica al grupo
%
%  info = pvm_freezegroup('group', size)   * info, size: int/array por comodidad
%
%  group (string) nombre del grupo
%  size  (int)    tamaño deseado del grupo para congelar
%  info  (int)    código de retorno
%       0 PvmOk
%     -14 PvmSysErr
%      -2 PvmBadParam
%     -18 PvmDupGroup
%     -20 PvmNotInGroup
%      -3 PvmMismatch
%				info, size pueden ser arrays por comodidad de
%			implementación (igual que pvm_getinst, pvm_gettid)
%
%  Implementación MEX completa: pvm_freezegroup.c, pvm_freezegroup.mexlx

