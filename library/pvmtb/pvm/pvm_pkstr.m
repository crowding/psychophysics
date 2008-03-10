%PVM_PKSTR		Empaqueta 1 string null-terminated
%
%  info = pvm_pkstr('str')
%
%  str(string) string a empaquetar null-terminated
%  info  (int) código retorno
%       0 PvmOk
%     -10 PvmNoMem
%     -15 PvmNoBuf
%      -4 PvmOverflow
%
%  Implementación MEX completa: src/pvm_pkstr.c, pvm/MEX/pvm_pkstr.mexlx

