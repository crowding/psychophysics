%PVM_SETSBUF		Cambia el buffer de envío actual
%
%  oldbuf = pvm_setsbuf(bufid)
%
%  bufid (int) >0 buffer de envío deseado
%              =0 para que no haya ninguno
%
%  oldbuf(int) antiguo buffer de envío
%      <0 código de error
%      -2 PvmBadParam
%     -16 PvmNoSuchBuf
%
%  Implementación MEX completa: src/pvm_setsbuf.c, pvm/MEX/pvm_setsbuf.mexlx

