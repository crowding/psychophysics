%PVM_BUFINFO		Información sobre buffer de mensajes
%
%  [info bfinfo] = pvm_bufinfo(bufid)	* bfinfo: struct [bytes,msgtag,tid]
%
%  bufid (int) identificador de buffer
%  info  (int) código retorno
%        0 PvmOk
%      -16 PvmNoSuchBuf
%       -2 PvmBadParam
%  bfinfo (struct) información del mensaje en buffer
%          bytes, msgtag, tid de la tarea de la que proviene
%
%  Implementación MEX completa: src/pvm_bufinfo.c, pvm/MEX/pvm_bufinfo.mexlx

