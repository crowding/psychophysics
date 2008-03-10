function [level, ctx, mmids, grpnam] = mmup()
%MMUP		Sube a siguiente nivel de sesión MM
%
%  [level ctx mmids grpnam] = mmup
%
%	level+1, +2,...max, max... en sucesivas llamadas.
%	Si se esta en el último nivel creado, se mantiene en él
%	  si no, se va subiendo de nivel hasta alcanzarlo
%	Internamente se cambia de grupo y contexto PVM,
%		aislando así de otros niveles
%
%	Se actualiza anotación level en mbox
%
%	Ver también: mmdown, mmis, mmlevel

level = 0;
ctx   = 0;						%%%%%%%%%
mmids =[];						% default
grpnam='';						%%%%%%%%%%
							% stat chk
if ~isempty (getenv ('PVMEPID'))			%%%%%%%%%%
	    error('mmup: no llamar desde instancia Matlab hija'), end
if ~pvme_is,error('mmup: no hay sesión PVM arrancada'), end
if ~mmis,   error('mmup: no hay sesión MM  arrancada'), end

%=== UP ===						%%%%
[level MMLEVELS MMGRPMAX] = mmlevels;			% UP
							%%%%
   old_ctx = pvm_getcontext;
if old_ctx~= MMLEVELS{level+1, 1}
		      error('mmup: inconsistencia nivel/ctx'), end
if size(MMLEVELS, 1) >level+1, level=level+1; end
       ctx = MMLEVELS{level+1, 1};
     mmids = MMLEVELS{level+1, 2};
    grpnam = MMLEVELS{level+1, 3};
if old_ctx~= pvm_setcontext(ctx)
		      error('mmup: inconsistencia pvm_setcontext'), end

putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX);
%=== UP ===						%%%%%%%%%%%%%%%%%%
							% Join grupo nivel
     inum = pvm_getinst(grpnam, pvm_mytid);		%%%%%%%%%%%%%%%%%%
  if inum<0,pvm_perror('mmup'), return, end

