%PVM_PKMESGBODY		Empaqueta cuerpo de mensaje (sin header) en otro mensaje
%
%  info = pvm_pkmesgbody(bufid)
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
%  Implementación MEX completa: pvm_pkmesgbody.c, pvm_pkmesgbody.mexlx

