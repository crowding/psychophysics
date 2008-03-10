%PVM_INITSEND		Limpia buffer envío por defecto y ajusta codificación
%
%  bufid = pvm_initsend [ (encoding) ]
%
%  encoding (int) codificación deseada (opcional)
%      0 PvmDataDefault 0 XDR (Default)
%      1 PvmDataRaw     1 sin codificación
%      2 PvmDataInPlace 2 los datos no se copian, se dejan donde están
%
%  bufid (int) identificador de buffer
%     <0 código error
%     -2 PvmBadParam
%    -10 PvmNoMem
%
%  Implementación MEX completa: src/pvm_initsend.c, pvm/MEX/pvm_initsend.mexlx

