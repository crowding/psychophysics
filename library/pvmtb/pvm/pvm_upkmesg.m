%PVM_UPKMESG		Desempaqueta mensaje en otro mensaje
%
%  bufid = pvm_upkmesg
%
%  bufid (int) identificador de buffer en donde queda mensaje desempaquetado
%      <0 código de error
%      -2 PvmBadParam
%     -16 PvmNoSuchBuf
%     -10 PvmNoMem
%      -5 PvmNoData
%     -15 PvmNoBuf
%      -3 PvmMismatch
%
%  Implementación MEX completa: pvm_upkmesg.c, pvm_upkmesg.mexlx

