function [level, ctx, mmids, grpnam] = mmdown()
%MMDOWN		Baja a nivel inferior de sesión MM
%
%  [level ctx mmids grpnam] = mmdown
%
%	level-1, -2,...0, 0... en sucesivas llamadas.
%	Si se esta en nivel 0, se mantiene en él
%	  si no, se va bajando de nivel hasta alcanzarlo
%	Internamente se cambia de grupo y contexto PVM,
%		aislando así de otros niveles
%
%	Se actualiza anotación level en mbox
%
%	Nivel 0 equivale a salirse del sistema de niveles
%		no se puede hacer mmclose del nivel 0.
%
%	Ver también: mmopen, mmclose, mmup, mmexit, mmkill

level = 0;						%%%%%%%%%%
ctx   = 0;						% defaults
mmids =[];						%%%%%%%%%%
grpnam='';
							%%%%%%%%%%
							% stat chk
if ~isempty (getenv ('PVMEPID'))			%%%%%%%%%%
		error('mmdown: no llamar desde instancia Matlab hija'), end
if ~pvme_is,	error('mmdown: no hay sesión PVM arrancada'), end
if ~mmis,	error('mmdown: no hay sesión MM  arrancada'), end
							%%%%%%
%=== DOWN ===						% DOWN
[level MMLEVELS MMGRPMAX] = mmlevels;			%%%%%%

   old_ctx = pvm_getcontext;
if old_ctx~= MMLEVELS{level+1,1}
		error('mmdown: inconsistencia nivel/ctx'), end
if level>0,  level   =level-1; end
       ctx = MMLEVELS{level+1, 1};
     mmids = MMLEVELS{level+1, 2};
    grpnam = MMLEVELS{level+1, 3};
if old_ctx~= pvm_setcontext(ctx)
		error('mmdown: inconsistencia pvm_setcontext'), end

putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX);
%=== DOWN ===						%%%%%%%%%%%%%%%%%%
							% Join grupo nivel
if level						%%%%%%%%%%%%%%%%%%
     inum = pvm_getinst(grpnam, pvm_mytid);
  if inum>0,	error('mmdown: inconsistencia pvm_getinst'), end
  if inum<0,	pvm_perror('mmdown'), return, end
end

