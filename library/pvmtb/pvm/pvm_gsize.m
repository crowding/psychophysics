%PVM_GSIZE		Devuelve el nº de instancias actualmente en el grupo
%
%  size = pvm_gsize('group')
%
%  group (string) nombre del grupo
%  size  (int)    número de instancias en el grupo
%      <0 código de error
%     -14 PvmSysErr
%     -19 PvmNoGroup
%      -2 PvmBadParam
%
%  Implementación MEX completa: src/pvm_gsize.c, pvm/MEX/pvm_gsize.mexlx

