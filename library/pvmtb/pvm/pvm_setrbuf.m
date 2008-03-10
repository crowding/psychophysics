%PVM_SETRBUF		Cambia el buffer de recepción actual
%
%  oldbuf = pvm_setrbuf(bufid)
%
%  bufid (int) >0 buffer de recepción deseado
%              =0 para que no haya ninguno
%
%  oldbuf(int) antiguo buffer de recepción
%      <0 código de error
%      -2 PvmBadParam
%     -16 PvmNoSuchBuf
%
%  Implementación MEX completa: src/pvm_setrbuf.c, pvm/MEX/pvm_setrbuf.mexlx

