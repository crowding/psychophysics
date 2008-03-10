%PVM_RECVINFO		Consulta mensaje en el Mailbox Global
%
%  bufid = pvm_recvinfo('name', index, flags)
%
%  name  (string) nombre de entrada, y
%  index (int)    índice en Mailbox de la entrada a consultar
%  flags (int)    opciones, OR de los siguientes bits
%       0 PvmMboxDefault	coincidencia exacta <name,index>
%       8 PvmMboxFirstAvail	seleccionar 1er índice >= especificado
%      16 PvmMboxReadAndDelete	leerla y borrarla
%      32 PvmMboxWaitForInfo	recvinfo bloqueante
%
%  bufid (int) id.buffer de recepción devuelto, listo para pvm_unpack
%      <0 código retorno
%     -32 PvmNotFound : no existe dicha clave (name-index)
%      -8 PvmDenied   : no se puede borrar
%     -10 PvmNoMem
%
%  Implementación MEX completa: src/pvm_recvinfo.c, pvm/MEX/pvm_recvinfo.mexlx

