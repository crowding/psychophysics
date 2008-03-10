%PVM_FREEBUF		Libera un buffer de mensajes
%
%  info = pvm_freebuf(bufid)
%
%  bufid (int) identificador de buffer
%  info  (int) código retorno
%       0 PvmOk
%      -2 PvmBadParam
%     -16 PvmNoSuchBuf
%
%  Implementación MEX completa: src/pvm_freebuf.c, pvm/MEX/pvm_freebuf.mexlx

