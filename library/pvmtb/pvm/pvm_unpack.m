%PVM_UNPACK		Des-empaqueta datos Matlab cualesquiera
%
%  [info names] = pvm_unpack [ ( 'vnam' [, 'vnam']...) ] * info: int/array 
%
%  vnam (string) nombres a dar a las variables
%          sólo se desempaquetan tantas como nombres se den
%          si no se da ninguno, se desempaquetan todas las que haya
%            con los nombres con que se empaquetaron
%
%  names (cell array strings) nombres originales de las variables
%
%  info (int/arr) vector códigos retorno (tantos como variables desempaquetadas)
%                                        (o menos, hasta 1er error)
%       0 PvmOk
%      -2 PvmBadParam (propio MEX, motivo: nombre incorrecto)
%      -3 PvmMismatch (propio MEX, motivo: no coincide ndim-dims/#elementos)
%     -24 PvmNotImpl  (propio MEX, motivo: desempaquetamiento no implementado)
%      -5 PvmNoData
%     -12 PvmBadMsg
%     -15 PvmNoBuf
%
%  Implementación MEX completa: src/pvm_unpack.c, pvm/MEX/pvm_unpack.mexlx

