%PVM_UPKSTR		Desempaqueta 1 string null-terminated
%
%  [info 'str'] = pvm_upkstr
%
%  str(string) string desempaquetado
%  info  (int) código retorno
%       0 PvmOk
%     -10 PvmNoMem
%     -15 PvmNoBuf
%      -4 PvmOverflow
%
%  Implementación MEX completa: src/pvm_upkstr.c, pvm/MEX/pvm_upkstr.mexlx

