%PVM_PKMESG		Empaqueta un mensaje en otro mensaje
%
%  info = pvm_pkmesg(bufid)
%
%  bufid (int) identificador de buffer
%  info  (int) código retorno
%       0 PvmOk
%      -2 PvmBadParam
%     -16 PvmNoSuchBuf
%     -10 PvmNoMem
%      -5 PvmNoData
%     -15 PvmNoBuf
%      -3 PvmMismatch
%
%  Implementación MEX completa: src/pvm_pkmesg.c, pvm/MEX/pvm_pkmesg.mexlx

