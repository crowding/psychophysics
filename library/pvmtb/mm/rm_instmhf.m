function RM_INSTMHF
%RM_INSTMHF		Pensado para instalar SKEL_RM como resource manager
%
%	Es que son muchos TAGs como para hacerlo a mano

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

if pvm_addmhf(-1,SM_SPAWN,    -1,'skel_rm')<0,	error('fallo para SM_SPAWN')
						end
if pvm_addmhf(-1,SM_EXEC,     -1,'skel_rm')<0,	error('fallo para SM_EXEC')
						end
if pvm_addmhf(-1,SM_EXECACK,  -1,'skel_rm')<0,	error('fallo para SM_EXECACK')
						end
if pvm_addmhf(-1,SM_TASK,     -1,'skel_rm')<0,	error('fallo para SM_TASK')
						end
if pvm_addmhf(-1,SM_CONFIG,   -1,'skel_rm')<0,	error('fallo para SM_CONFIG')
						end
if pvm_addmhf(-1,SM_ADDHOST,  -1,'skel_rm')<0,	error('fallo para SM_ADDHOST')
						end
if pvm_addmhf(-1,SM_DELHOST,  -1,'skel_rm')<0,	error('fallo para SM_DELHOST')
						end
if pvm_addmhf(-1,SM_ADD,      -1,'skel_rm')<0,	error('fallo para SM_ADD')
						end
if pvm_addmhf(-1,SM_ADDACK,   -1,'skel_rm')<0,	error('fallo para SM_ADDACK')
						end
if pvm_addmhf(-1,SM_NOTIFY,   -1,'skel_rm')<0,	error('fallo para SM_NOTIFY')
						end
if pvm_addmhf(-1,SM_TASKX,    -1,'skel_rm')<0,	error('fallo para SM_TASKX')
						end
if pvm_addmhf(-1,SM_HOSTX,    -1,'skel_rm')<0,	error('fallo para SM_HOSTX')
						end
if pvm_addmhf(-1,SM_HANDOFF,  -1,'skel_rm')<0,	error('fallo para SM_HANDOFF')
						end
if pvm_addmhf(-1,SM_SCHED,    -1,'skel_rm')<0,	error('fallo para SM_SCHED')
						end
if pvm_addmhf(-1,SM_STHOST,   -1,'skel_rm')<0,	error('fallo para SM_STHOST')
						end
if pvm_addmhf(-1,SM_STHOSTACK,-1,'skel_rm')<0,	error('fallo para SM_STHOSTACK')
						end

