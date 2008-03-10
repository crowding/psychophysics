function [level, ctx, mmids, grpnam] = mmopen()
%MMOPEN		Crea nuevo nivel de sesión MM
%
%  [level ctx mmids grpnam] = mmopen
%
%	level 1, 2, 3... en sucesivas llamadas.
%	Independientemente del nivel en que se esté, crea un nuevo nivel
%	  mayor que el último existente, y deja al que llama en él
%	Internamente se cambia de contexto PVM, aislando de otros niveles
%	Las instancias del nivel forman un grupo PVM, anotado en mbox
%		cell MMLEVELS{ctx [mmids] 'grpnam'}, indexado por level+1
%
%	Si fuera necesario se inicia PVM, anotando PVM_STARTER en mbox
%	Si fuera necesario se inicia anotación level/MMLEVELS/MMGRPMAX
%
%	Ver también: mmclose, mmup, mmdown, mmexit, mmkill

level = 0;						%%%%%%%%%
ctx   = 0;						% default
mmids =[];						%%%%%%%%%
grpnam='';
							%%%%%%%%%%
							% stat chk
if ~isempty (getenv ('PVMEPID'))			%%%%%%%%%%
		error('mmopen: no desde instancia Matlab hija'), end
							%%%%%%%%%%
if ~pvme_is						% OPEN PVM
  if pvme_start_pvmd, pvm_perror('mmopen'), return, end	%%%%%%%%%%
			PVMSTARTER = pvm_mytid;
  putmbox('PVMSTARTER', PVMSTARTER);
end
if ~pvme_is,	error('mmopen: error interno comprobando pvme_is'), end
							%%%%%%%%%%%
if ~mmis						% OPEN mbox
  if ctx~=pvm_getcontext				%%%%%%%%%%%
		error('mmopen: inconsistencia pvm_getcontext'), end
  MMGRPMAX=0; grpnam=''; TAGTFY=668;
     mhid =pvm_addmhf(-1,TAGTFY,-1,'quithandler_mm');
  if mhid <0,	pvm_perror('mmopen'), error('mmopen: no puedo pvm_addmhf'), end
  MMLEVELS =  {ctx mhid  grpnam};
  putmbox('MMLEVELS',level, MMLEVELS, MMGRPMAX);
end
if ~mmis,	error('mmopen: error interno comprobando mmis'), end

%=== OPEN ===						%%%%%%
[level, MMLEVELS, MMGRPMAX] = mmlevels;			% OPEN
							%%%%%%
   old_ctx = pvm_getcontext;
if old_ctx~= MMLEVELS{level+1,1}
		error('mmopen: inconsistencia nivel/ctx'), end
       ctx = pvm_newcontext;
if old_ctx~= pvm_setcontext(ctx)
		error('mmopen: inconsistencia pvm_setcontext'), end

level=size(MMLEVELS, 1);
           MMGRPMAX=      MMGRPMAX + 1  ;
  grpnam=['MMGRP' int2str(MMGRPMAX)];
MMLEVELS(level+1,:) = {ctx mmids grpnam};

putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX);
%=== OPEN ===
							%%%%%%%%%%%%%%%%%%
							% Join grupo nivel
   info = pvm_joingroup(grpnam);			%%%%%%%%%%%%%%%%%%
if info>0,	error('mmopen: inconsistencia pvm_joingroup'), end
if info<0,	pvm_perror('mmopen'), end

