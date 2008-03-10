%PVM_GETTID		Devuelve el TID de una instancia en un grupo
%
%  tid = pvm_gettid('group', inum)      * tid, inum: int/array
%
%  group (string) nombre del grupo
%  inum (int/arr) nº instancia dentro del grupo
%  tid  (int/arr) identificador tarea PVM
%     <0 código de error
%    -14 PvmSysErr
%     -2 PvmBadParam
%    -19 PvmNoGroup
%    -21 PvmNoInst
%
%  Implementación MEX completa: src/pvm_gettid.c, pvm/MEX/pvm_gettid.mexlx

