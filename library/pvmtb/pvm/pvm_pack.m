function info=pvm_pack(varargin)
%PVM_PACK		Empaqueta datos Matlab cualesquiera
%
%  info = pvm_pack(var [,var]...)	* info: int/array
%
%  info (int/array) vector códigos retorno (tantos como vars)
%                                          (o menos, hasta 1er error)
%       0 PvmOk
%      -2 PvmBadParam (propio MEX, motivo: clase desconocida)
%     -24 PvmNotImpl  (propio MEX, motivo: empaquetamiento no implementado)
%     -10 PvmNoMem
%     -15 PvmNoBuf
%      -4 PvmOverflow
%
%  Implementación MEX completa: src/pvm_pack.c, pvm/MEX/pvm_pack.mexlx

