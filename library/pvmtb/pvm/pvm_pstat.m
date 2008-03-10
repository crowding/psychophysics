%PVM_PSTAT		Estado de un proceso bajo PVM
%
%  stat = pvm_pstat(tid)	* extensión para arrays pvme_pstat
%
%  tid (int/array) tids de los cuales se desea información de estado
%  stat(int/array) información de estado
%       0 PvmOk
%      -2 PvmBadParam
%     -14 PvmSysErr
%     -31 PvmNoTask
%
%  Implementación MEX completa: src/pvm_pstat.c, pvm/MEX/pvm_pstat.mexlx

