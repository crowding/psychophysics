function info=pvme_pack(varargin)
%PVME_PACK		Empaqueta datos Matlab cualesquiera agrupados con {}
%
%  info = pvme_pack(var [,var]...)	* info: int/array
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
%  Implementación MEX quasicompleta: src/pvm_pack.c, pvm/MEX/pvm_pack.mexlx

info=pvm_pack(varargin);

%
% La única utilidad de esta línea es conjuntar todos los argumentos
% en un cellarray, para que Matlab sepa cuántas variables van en el
% mensaje.
%
% PVM sólo ofrece message-tag para saber qué tipo de mensaje es.
% En función del tag se debe adivinar cuántas variables y de qué tipo
% van en el mensaje.
%
% Este método (cell-array) permite saber de antemano que sólo habrá
% una variable de tipo cellarray, y tras recibirla se podrá saber
% cuántas componentes tiene, e incluso cambiarles el nombre si se desea
%
% La única alternativa sería usar pvm_pack_.mexlx directamente
% enviando variables de 1 en 1. Si se permite enviar varias, hay
% que detectar el fin del mensaje por el método de pasarse, lo
% que produce un warning "End of buffer" bastante enojoso, queda
% duda de si está todo bien o algo ha salido mal.
%
