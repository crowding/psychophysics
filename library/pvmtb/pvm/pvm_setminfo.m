%PVM_SETMINFO		Ajusta información sobre mensajes
%
%  info = pvm_setminfo(bufid, msginfo)	* msginfo: struct [len,ctx,tag,wid,
%							   enc,crc,src,dst]
%
%  bufid   (int)   identificador del buffer conteniendo el mensaje
%  info    (int)   código de retorno
%       0  PvmOk
%      -2  PvmBadParam
%     -16  PvmNoSuchBuf
%
%  msginfo (struct pvmminfo) información sobre el mensaje
%                            todos los campos son (int)
%	len	longitud del mensaje
%	ctx	contexto
%	tag	código (etiqueta)
%	wid	identificador de espera (wait id)
%	enc	codificación (XDR, raw, in-place)
%	crc	checksum
%	src	tid fuente
%	dst	tid destino
%
%  Implementación MEX completa: src/pvm_setminfo.c, pvm/MEX/pvm_setminfo.mexlx

