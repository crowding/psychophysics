function mhid = pvm_addmhf(src, tag, ctx, MatlabCMD)
%PVM_ADDMHF		Instala función manejadora de mensajes
%
%  mhid = pvm_addmhf(src, tag, ctx, 'MatlabCMD')
%
%  src   (int) tid de la tarea PVM fuente del mensaje a manejar
%  tag   (int) tag                        del mensaje a manejar
%  ctx   (int) contexto PVM en que se envió el  "     a manejar
%  MatlabCMD (string) comando de manejo del   mensaje
%			debe aceptar 1 arg numérico (bufid)
%
%  mhid  (int) >=0 identificador asignado por PVM al manejador
%     -33 PvmExists	ya hay manejador con ese (src,tag,ctx)
%
%  Implementación MEX quasi-completa: src/pvm_mhf.c, pvm/MEX/pvm_mhf.mexlx

mhid = pvm_mhf('add', src, tag, ctx, MatlabCMD);
