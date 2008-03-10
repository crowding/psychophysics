%PVM_GETINST		Devuelve el nº instancia en un grupo de una tarea PVM
%
%  inum = pvm_getinst('group', tid)     * inum, tid: int/array
%
%  group (string) nombre del grupo
%  tid  (int/arr) identificador tarea PVM
%  inum (int/arr) nº instancia dentro del grupo
%     <0 código de error
%    -14 PvmSysErr
%     -2 PvmBadParam
%    -19 PvmNoGroup
%    -20 PvmNotInGroup
%
%  Implementación MEX completa: src/pvm_getinst.c, pvm/MEX/pvm_getinst.mexlx

