%PVM_GETMBOXINFO	Consulta mensajes en el Mailbox Global
%
%  [info mbinfo] = pvm_getmboxinfo('pattern')	* mbinfo: struct pvmmboxinfo
%
%  pattern(string) expresión regular (* para todo)
%  info   (int)    código de retorno
%       0 PvmOk
%     -10 PvmNoMem
%      -8 PvmDenied
%
%  mbinfo (struct pvmmboxinfo) información sobre las entradas en Mailbox Global
%   campos:(string) name	nombre de la clase
%             (int) nentries	número de entradas para esta clase (nombre)
%   (int[nentries]) indices	índices      de las sucesivas entradas
%   (int[nentries]) owners	propietarios de las sucesivas entradas
%   (int[nentries]) flags	flags        de las sucesivas entradas
%
%  Implementación MEX completa: pvm_getmboxinfo.c, pvm_getmboxinfo.mexlx

