%PVM_MKBUF		Crea un nuevo buffer de mensajes
%
%  bufid = pvm_mkbuf [ (encoding) ]
%
%  encoding (int) codificación deseada (opcional)
%         0 PvmDataDefault XDR (Default)
%         1 PvmDataRaw     sin codificación
%         2 PvmDataInPlace los datos no se copian, se dejan donde están
%
%  bufid (int) identificador de buffer
%        <0 código error
%        -2 PvmBadParam
%       -10 PvmNoMem
%
%  Implementación MEX completa: src/pvm_mkbuf.c, pvm/MEX/pvm_mkbuf.mexlx

