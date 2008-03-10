function info = skel_rm(bufid)
%SKEL_RM		Manejador mensajes para Resource Manager
%
%	Pensado para instalarlo con rm_instmhf.m
%		consultar dicho script para ver cuáles mensajes maneja
%		como todo manejador, acepta bufid, da igual retorno
%
%	En este esqueleto sencillamente se responde absolutamente nada
%		pero se imprime el mensaje y se responde que no
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
% #define SM_SPAWN        (SM_FIRST+0)    /* t<>R like TM_SPAWN */
% #define SM_EXEC         (SM_FIRST+1)    /* R->d like DM_EXEC */
% #define SM_EXECACK      (SM_FIRST+2)    /* d->R like DM_EXECACK */
% #define SM_TASK         (SM_FIRST+3)    /* t<>R like TM_TASK */
% #define SM_CONFIG       (SM_FIRST+4)    /* t<>R like TM_CONFIG */
% #define SM_ADDHOST      (SM_FIRST+5)    /* t<>R like TM_ADDHOST */
% #define SM_DELHOST      (SM_FIRST+6)    /* t<>R like TM_DELHOST */
% #define SM_ADD          (SM_FIRST+7)    /* R->d like DM_ADD */
% #define SM_ADDACK       (SM_FIRST+8)    /* d->R like DM_ADDACK */
% #define SM_NOTIFY       (SM_FIRST+9)    /* t->R like TM_NOTIFY */
% #define SM_TASKX        (SM_FIRST+10)   /* d->R notify of task exit */
% #define SM_HOSTX        (SM_FIRST+11)   /* d->R notify sched of host delete */
% #define SM_HANDOFF      (SM_FIRST+12)   /* R->d pvmd to new sched */
% #define SM_SCHED        (SM_FIRST+13)   /* t<>R like TM_SCHED */
% #define SM_STHOST       (SM_FIRST+14)   /* d->H start slave pvmds */
% #define SM_STHOSTACK    (SM_FIRST+15)   /* H->d like DM_STARTACK */
%
%	0x80040001 = -2147221503 = SM_SPAWN = SM_FIRST
%	0x80040002 = -2147221502 = SM_EXEC
%	0x80040003 = -2147221501 = SM_EXECACK
%	0x80040004 = -2147221500 = SM_TASK
%	0x80040005 = -2147221499 = SM_CONFIG
%	0x80040006 = -2147221498 = SM_ADDHOST
%	0x80040007 = -2147221497 = SM_DELHOST
%	0x80040008 = -2147221496 = SM_ADD
%	0x80040009 = -2147221495 = SM_ADDACK
%	0x8004000A = -2147221494 = SM_NOTIFY
%	0x8004000B = -2147221493 = SM_TASKX
%	0x8004000C = -2147221492 = SM_HOSTX
%	0x8004000D = -2147221491 = SM_HANDOFF
%	0x8004000E = -2147221490 = SM_SCHED
%	0x8004000F = -2147221489 = SM_STHOST
%	0x80040010 = -2147221488 = SM_STHOSTACK
%
%	Datos tomados del fuente $PVM_ROOT/rm/srm.h y srm.c
%	/* Need to do a config otherwise the first host gets messed up
%		if we start the daemon */
% #define MAX_MESSAGE     16      /* Make sure this number stays right :) */
% message_type Messages[MAX_MESSAGE] =
% {     /*      Message Tag             Message Code */
%	{       SM_TASK,                sm_task         }, /* 0 */
%	{       SM_TASKX,               sm_taskx        },
%	{       SM_SPAWN,               sm_spawn        },
%	{       SM_EXEC,                sm_exec         },
%	{       SM_EXECACK,             sm_execack      },
%	{       SM_CONFIG,              sm_config       }, /* 5 */
%	{       SM_ADDHOST,             sm_addhost      },
%	{       SM_DELHOST,             sm_delhost      },
%	{       SM_ADD,                 sm_add          },
%	{       SM_ADDACK,              sm_addack       },
%	{       SM_NOTIFY,              sm_notify       }, /* 10 */
%	{       SM_HOSTX,               sm_hostx        },
%	{       SM_HANDOFF,             sm_handoff      },
%	{       SM_SCHED,               sm_sched        },
%	{       SM_STHOST,              sm_sthost       },
%	{       SM_STHOSTACK,           sm_sthostack    }  /* 15 */
% };
%

	info = 0;
global	PvmDataFoo PvmResvTids			% Constantes PVM
global	SM_SPAWN   SM_EXEC    SM_EXECACK SM_TASK
global	SM_CONFIG  SM_ADDHOST SM_DELHOST SM_ADD
global	SM_ADDACK  SM_NOTIFY  SM_TASKX   SM_HOSTX
global	SM_HANDOFF SM_SCHED   SM_STHOST  SM_STHOSTACK
PvmDataFoo  =           0;
PvmResvTids =          11;
SM_SPAWN    = -2147221503;
SM_EXEC     = -2147221502;
SM_EXECACK  = -2147221501;
SM_TASK     = -2147221500;
SM_CONFIG   = -2147221499;
SM_ADDHOST  = -2147221498;
SM_DELHOST  = -2147221497;
SM_ADD      = -2147221496;
SM_ADDACK   = -2147221495;
SM_NOTIFY   = -2147221494;
SM_TASKX    = -2147221493;
SM_HOSTX    = -2147221492;
SM_HANDOFF  = -2147221491;
SM_SCHED    = -2147221490;
SM_STHOST   = -2147221489;
SM_STHOSTACK= -2147221488;

  [info minfo] = pvm_getminfo(bufid);
TAG    =minfo.tag;
switch TAG
case SM_TASK,		sm_task		(minfo);
case SM_TASKX,		sm_taskx	(minfo);
case SM_SPAWN,		sm_spawn	(minfo);
case SM_EXEC,		sm_exec		(minfo);
case SM_EXECACK,	sm_execack	(minfo);
case SM_CONFIG,		sm_config	(minfo);
case SM_ADDHOST,	sm_addhost	(minfo);
case SM_DELHOST,	sm_delhost	(minfo);
case SM_ADD,		sm_add		(minfo);
case SM_ADDACK,		sm_addack	(minfo);
case SM_NOTIFY,		sm_notify	(minfo);
case SM_HOSTX,		sm_hostx	(minfo);
case SM_HANDOFF,	sm_handoff	(minfo);
case SM_SCHED,		sm_sched	(minfo);
case SM_STHOST,		sm_sthost	(minfo);
case SM_STHOSTACK,	sm_sthostack	(minfo);
otherwise
	warning('skel_rm: llega mensaje que no corresponde a un rmanager')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_task(minfo);
global	PvmDataFoo PvmResvTids	SM_TASK			% Constantes PVM
disp('skel_rm: mensaje  SM_TASK')
  [info where]=pvm_upkint;
  fprintf('sm_task: where=%d\n',where);

  pvm_setopt(PvmResvTids,1);
  pvm_initsend (PvmDataFoo);
  FROMTID=minfo.src;			% sacar fuente
  pvm_setminfo(pvm_getsbuf, minfo);

  pvm_pkint(-2);			% respuesta &error según srm.c?!?
% pack_task_list(where)			% según srm.c
  pvm_send(FROMTID, SM_TASK);		% responder
  pvm_setopt(PvmResvTids,0);

disp('sm_task: respondiendo -2 en SM_TASK, falta pack_task_list()?');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_taskx(minfo);
disp('skel_rm: mensaje SM_TASKX')
  [info tid   ]=pvm_upkint;
% [info status]=pvm_upkint;
  fprintf('sm_taskx: tid=0x%x, habría que matarla\n', tid);

disp('sm_taskx: ignorado');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_spawn(minfo);
global	PvmDataFoo PvmResvTids	SM_SPAWN		% Constantes PVM
disp('skel_rm: mensaje SM_SPAWN')
  [info buf  ]=pvm_upkstr;
  [info flag ]=pvm_upkint;
  [info where]=pvm_upkstr;
  [info count]=pvm_upkint;
  fprintf('sm_spawn: buf=%s, flag=0x%x, where=%s, count=%d\n',...
		     buf,    flag,      where,    count);
  [info argc ]=pvm_upkint;  fprintf('sm_spawn: argc=%d', argc);
for i=1:argc
  [info argv ]=pvm_upkstr;  fprintf(', %s', argc);
end,			    fprintf('\n');
  [info out_tid]=pvm_upkint;
  [info out_ctx]=pvm_upkint;
  [info out_tag]=pvm_upkint;
  fprintf('sm_spawn: OUTPUT: tid=0x%x, ctx=%d, tag=0x%x\n',...
			 out_tid,  out_ctx,out_tag);
  [info trc_tid]=pvm_upkint;
  [info trc_ctx]=pvm_upkint;
  [info trc_tag]=pvm_upkint;
  fprintf('sm_spawn: TRACER: tid=0x%x, ctx=%d, tag=0x%x\n',...
			 trc_tid,  trc_ctx,trc_tag);
  [info nenv ]=pvm_upkint;  fprintf('sm_spawn: nenv=%d', nenv);
for i=1:nenv
  [info envv ]=pvm_upkstr;  fprintf(', %s', envv);
end,			    fprintf('\n');

  pvm_setopt(PvmResvTids,1);
  pvm_initsend (PvmDataFoo);
  FROMTID=minfo.src;			% sacar fuente

  pvm_pkint(count);			% respuesta #tareas
  pvm_setminfo(pvm_getsbuf, minfo);
  for i=1:count, pvm_pkint(-6); end	% PvmNoHost
  pvm_send(FROMTID, SM_SPAWN);		% responder
  pvm_setopt(PvmResvTids,0);

disp('sm_spawn: respondiendo PvmNoHost en SM_SPAWN');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_exec(minfo);
disp('skel_rm: mensaje SM_EXEC no debe ser llamado')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_execack(minfo);
disp('skel_rm: mensaje SM_EXECACK')
  [info count]=pvm_upkint;
  [info tid  ]=pvm_upkint;
  fprintf('sm_execack: count=%d, tid=0x%x\n',...
		       count,    tid);
disp('sm_execack: no responder');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_config(minfo);
global	PvmDataFoo PvmResvTids	SM_CONFIG		% Constantes PVM
disp('skel_rm: mensaje SM_CONFIG')

  pvm_setopt(PvmResvTids,1);
  pvm_initsend (PvmDataFoo);
  FROMTID=minfo.src;			% sacar fuente
  pvm_setminfo(pvm_getsbuf, minfo);

% pack_host_list()			% según srm.c
  pvm_send(FROMTID, SM_CONFIG);		% responder
  pvm_setopt(PvmResvTids,0);

disp('sm_config: respondiendo nada en SM_CONFIG, falta pack_host_list()?');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_addhost(minfo);
global	PvmDataFoo PvmResvTids	SM_ADDHOST		% Constantes PVM
disp('skel_rm: mensaje SM_ADDHOST')
  [info nhost]=pvm_upkint;  fprintf('sm_addhost: nhost=%d', nhost);
for i=1:nhost
  [info hname]=pvm_upkstr;  fprintf(', %s', hname);
end,			    fprintf('\n');

  pvm_setopt(PvmResvTids,1);
  pvm_initsend (PvmDataFoo);
  FROMTID=minfo.src;			% sacar fuente
  pvm_setminfo(pvm_getsbuf, minfo);

% pvm_pkint(nhost);			% encargar #hosts
% for i=1:nhost, pvm_pkstr(hname); end	% los de antes
% pvm_send(our_host.tid |		% al que se dijo con pvm_reg_rm
%     TIDPVMD, SM_ADD);
% pvm_recv(-1, SM_ADDACK);
% [info count]=pvm_upkint;
% [info narch]=pvm_upkint;
% pvm_initsend(PvmDataFoo);
% pvm_setminfo(pvm_getsbuf, minfo)

  count=0; pvm_pkint(count);
  narch=0; pvm_pkint(narch);

  pvm_send(FROMTID, SM_ADDHOST);	% responder
  pvm_setopt(PvmResvTids,0);

disp('sm_addhost: respondiendo 0 host/archs en SM_ADDHOST');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_delhost(minfo);
global	PvmDataFoo PvmResvTids SM_DELHOST		% Constantes PVM
disp('skel_rm: mensaje SM_DELHOST')
  [info nhost]=pvm_upkint;  fprintf('sm_delhost: nhost=%d', nhost);
for i=1:nhost
  [info hname]=pvm_upkstr;  fprintf(', %s', hname);
end,			    fprintf('\n');

  pvm_setopt(PvmResvTids,1);
  pvm_initsend (PvmDataFoo);
  FROMTID=minfo.src;			% sacar fuente
  pvm_setminfo(pvm_getsbuf, minfo);

% rc=pvm_delhosts(hname, count, status);% según srm.c

  rc    =0; pvm_pkint(rc    );
  status=0; pvm_pkint(status);

  pvm_send(FROMTID, SM_DELHOST);	% responder
  pvm_setopt(PvmResvTids,0);

disp('sm_delhost: respondiendo 0 rc/status en SM_DELHOST');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_add(minfo);
disp('skel_rm: mensaje SM_ADD no debe ser llamado')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_addack(minfo);
disp('skel_rm: mensaje SM_ADDACK no debe ser llamado')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_notify(minfo);
disp('skel_rm: mensaje SM_NOTIFY')
  [info flags]=pvm_upkint;
  [info  ctx ]=pvm_upkint;
  [info code ]=pvm_upkint;
  [info count]=pvm_upkint;
  fprintf('sm_notify: flags=0x%x, ctx=0x%x, code=%d, count=%d\n',...
		      flags,      ctx,      code,    count);

disp('sm_notify: ignorado');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_hostx(minfo);
disp('skel_rm: mensaje SM_HOSTX')
  [info tid]=pvm_upkint;
  fprintf('sm_hostx: tid=0x%x, habría que matarla\n', tid);

disp('sm_hostx: ignorado');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_handoff(minfo);
disp('skel_rm: mensaje SM_HANDOFF no debe ser llamado')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_sched(minfo);
global	PvmDataFoo PvmResvTids SM_SCHED			% Constantes PVM
disp('skel_rm: mensaje SM_SCHED')
  pvm_setopt(PvmResvTids,1);
  pvm_initsend (PvmDataFoo);
  FROMTID=minfo.src;			% sacar fuente
  pvm_setminfo(pvm_getsbuf, minfo);

  pvm_pkint(-2);			% respuesta &error según srm.c?!?
  pvm_send(FROMTID, SM_SCHED);		% responder
  pvm_setopt(PvmResvTids,0);

disp('sm_task: respondiendo -2 en SM_SCHED');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_sthost(minfo);
disp('skel_rm: mensaje SM_STHOST no debe ser llamado')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sm_sthostack(minfo);
disp('skel_rm: mensaje SM_STHOSTACK no debe ser llamado')

