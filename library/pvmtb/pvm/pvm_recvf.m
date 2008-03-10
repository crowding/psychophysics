function pvm_recvf(MatlabCMD)
%PVM_RECVF		Redefine función comparación usada para aceptar mensajes
%
%  pvm_recvf [ ('MatlabCMD') ]
%
%  MatlabCMD (string) comando de comparación de mensajes
%			debe aceptar 3 args numéricos (bufid,int,tag)
%	     (vacío)  para volver a dejar la función inicial
%
%  Implementación MEX completa: src/pvm_recvf.c, pvm/MEX/pvm_recvf.mexlx
%
%	SINOPSIS PARA MatlabCMD
%
%  cc = function(bufid, tid, tag)
%
%  bufid(int) identificador de mensaje a comparar
%  tid  (int) tid de tarea PVM deseada por el usuario
%  tag  (int) tag de mensaje "
%
%  cc   (int)	código de condición para indicar a PVM que debe...
%	<0	retornar inmediatamente con este código de error
%	 0	no tomar este mensaje (bufid)
%	 1	sí tomar este mensaje, dejar de scanear mensajes
%	>1	rango para este mensaje, seguir escaneando y quedarse con máx.
%
%	Ver página man pvm_recvf(3PVM)

