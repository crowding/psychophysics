%PVM_DELINFO		Borra entrada en el Mailbox Global
%
%  info = pvm_delinfo('name', index, flags)
%
%  name  (string) nombre de entrada, y
%  index (int) índice en Mailbox de la entrada a borrar
%  flags (int) 0, ignorado
%  info  (int) código de retorno
%       0 PvmOk
%     -32 PvmNotFound : no existe dicha clave (name-index)
%      -8 PvmDenied   : no se puede borrar
%
%  Implementación MEX completa: src/pvm_delinfo.c, pvm/MEX/pvm_delinfo.mexlx

