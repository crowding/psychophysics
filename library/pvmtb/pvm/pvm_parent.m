%PVM_PARENT		Devuelve el tid de la tarea PVM que hizo spawn de ésta
%
%  tid = pvm_parent
%
%  tid (int) identificador de la tarea que hizo spawn de ésta
%      >0 ptid
%     -14 PvmSysErr
%     -23 PvmNoParent
%
%  Implementación MEX completa: src/pvm_parent.c, pvm/MEX/pvm_parent.mexlx

