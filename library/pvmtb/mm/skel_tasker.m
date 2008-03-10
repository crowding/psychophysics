function info = skel_tasker(bufid)
%SKEL_TASKER		Manejador mensajes SM_STTASK
%
%	Pensado para instalarlo con pvm_addmhf(src,tag,ctx, 'skel_tasker')
%		por ejemplo: pvm_addmhf(-1, -2147221487, 0, 'skel_tasker')
%		como todo manejador, acepta bufid, da igual retorno
%
%	En este esqueleto sencillamente se responde que no se arranca nada
%		pero se imprime el mensaje y se responde SM_TASKX
%
%	Datos tomados de $PVM_ROOT/include/pvm3.h
%
% #define PvmDataDefault  0               /* XDR encoding */
% #define PvmDataFoo PvmDataDefault       /* Internal use */
% #define PvmResvTids    11 /* allow reserved message tids and codes */
%
%
%	Datos tomados de $PVM_ROOT/include/pvmproto.h
%
% #define SM_FIRST        (int)0x80040001 /* first SM_ message */
% #define SM_TASK         (SM_FIRST+3)    /* t<>R like TM_TASK */
% #define SM_TASKX        (SM_FIRST+10)   /* d->R notify of task exit */
% #define SM_STTASK       (SM_FIRST+16)   /* d->T start task */
%
%	0x80040001 = -2147221503 = SM_FIRST
%	0x80040004 = -2147221500 = SM_TASK
%	0x8004000B = -2147221493 = SM_TASKX
%	0x80040011 = -2147221487 = SM_STTASK
%
%	Datos tomados de pág man pvm_reg_tasker
%
%	The format of the SM_STTASK message is:
%	int tid               // of task
%	int flags             // as passed to spawn()
%	string path           // absolute path of the executable
%	int argc              // number of args to process
%	string argv[argc]     // args
%	int nenv              // number of envars to pass to task
%	string env[nenv]      // environment strings
%
%	The format of the SM_TASKX message is:
%	int tid               // of task
%	int status            // the Unix exit status (from wait())
%	int u_sec             // user time used by the task, seconds
%	int u_usec            // microseconds
%	int s_sec             // system time used by the task, seconds
%	int s_usec            // microseconds
%

info = 0;
PvmDataFoo  =  0;			% Constantes PVM
PvmResvTids = 11;
SM_STTASK=-2147221487;
SM_TASKX =-2147221493;

  [info minfo] = pvm_getminfo(bufid);
     if minfo.tag~=SM_STTASK
	error('skel_tasker: me llega mensaje que no es SM_STTASK'), end
FROMTID=minfo.src;			% sacar fuente

disp('skel_tasker: mensaje SM_STTASK: arrancar tarea');
pvm_setopt  (PvmResvTids,1);
pvm_initsend(PvmDataFoo);

  [info tid  ]=pvm_upkint;
  [info flags]=pvm_upkint;
  [info path ]=pvm_upkstr;
  fprintf('skel_tasker: tid=0x%x, flags=0x%x, path=%s\n',tid,flags,path);
  [info argc ]=pvm_upkint;
  fprintf('skel_tasker: %d argumentos: ',argc);
for i=1:argc
  [info argv ]=pvm_upkstr;
  fprintf(', %s ',argv);
end
  fprintf('\n');
  [info nenv ]=pvm_upkint;
  fprintf('skel_tasker: %d variables entorno: ',nenv);
for i=1:nenv
  [info env  ]=pvm_upkstr;
  fprintf(', %s ',env);
end
  fprintf('\n');

  pvm_pkint(tid);		% respuesta sobre esta tarea
  pvm_pkint( 0 );		% UNIX exit status, 0 si no
  pvm_pkint( 0 ); pvm_pkint(0);	% UserTime secs/usecs
  pvm_pkint( 0 ); pvm_pkint(0);	% SystTime secs/usecs

disp('skel_tasker: respondiendo que no podemos en SM_TASKX');
pvm_send  (FROMTID, SM_TASKX);		% responder
pvm_setopt(PvmResvTids,    0);

