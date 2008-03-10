function [level, ctx, mmids, grpnam] = mmclose()
%MMCLOSE	Anula el nivel actual de sesión MM
%
%  [level ctx mmids grpnam] = mmclose
%
%	level 2, 1, 0... en sucesivas llamadas.
%	Abandona el nivel, pasando al inmediatamente inferior (0 si no hay)
%	El nivel queda anulado. Los niveles superiores descienden 1 nivel
%	  se matan las instancias del nivel abandonado, salvo la que anula
%	Las instancias del nivel (salvo la madre) están anotadas en mbox
%		cell MMLEVELS{ctx [mmids] 'grpnam'}, indexado por level+1
%	Se actualiza anotación level/MMLEVELS/MMGRPMAX en mbox
%	Si fuera apropiado se finaliza PVM, borrando PVM_STARTER en mbox
%
%	Internamente se cambia de contexto PVM, aislando de otros niveles
%	Nivel 0 equivale a salirse del sistema de niveles
%	  no se puede hacer mmclose del nivel 0.
%
%	Ver también: mmopen, mmup, mmdown, mmexit, mmkill

level = 0;						%%%%%%%%%%
ctx   = 0;						% defaults
mmids =[];						%%%%%%%%%%
grpnam='';
							%%%%%%%%%%
							% stat chk
if ~isempty(  getenv('PVMEPID'))			%%%%%%%%%%
		error('mmclose: no llamar desde instancia MM hija'), end
if ~pvme_is,	error('mmclose: no hay sesión PVM arrancada'), end
if ~mmis,	error('mmclose: no hay sesión MM  arrancada'), end
							%%%%%%%%%
							% sem chk
[level ctx mmids grpnam] = mmlevel;			%%%%%%%%%
if level==0,	error('mmclose: no se puede en nivel 0'), end

%=== LEAVE ===						%%%%%%%
if ~isempty(mmids)					% LEAVE
 [info retval]=mmeval('mmexit');			%%%%%%%
       retval=[retval{:}];
  if (isnumeric(info) &      info)     |...
     (iscellnum(info) & any([info{:}]))|...
			any([retval{:}])
	warning('mmclose: mmexit falló en hijas')
	if any(pvm_kill(mmids)), pvm_perror('mmclose'), return, end
  end
end
if pvm_lvgroup(grpnam)~=0, pvm_perror('mmclose'), return, end
							%%%%%%%
%=== CLOSE ===						% CLOSE
[level MMLEVELS MMGRPMAX] = mmlevels;			%%%%%%%

   old_ctx = pvm_getcontext;
if old_ctx~= MMLEVELS{level+1, 1}
	     error('mmclose: inconsistencia nivel/ctx'), end
if pvm_freecontext(old_ctx)
	     pvm_perror('mmclose'), return, end
MMLEVELS(level+1,:) = [];

     level = level-1;
       ctx = MMLEVELS{level+1, 1};
     mmids = MMLEVELS{level+1, 2};
    grpnam = MMLEVELS{level+1, 3};
if old_ctx~= pvm_setcontext(ctx)
	     error('mmclose: inconsistencia pvm_setcontext'), end

putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX);
%=== CLOSE ===						%%%%%%%%%%%%%%%%%%
							% Join grupo nivel
if level						%%%%%%%%%%%%%%%%%%
     inum =	pvm_getinst(grpnam, pvm_mytid);
  if inum>0,	error('mmclose: inconsistencia pvm_getinst'), end
  if inum<0,	pvm_perror('mmclose'), return, end
end
							%%%%%%%
%=== ERASE ===						% ERASE
if size(MMLEVELS,1) == 1				%%%%%%%
  if pvm_delmhf ( MMLEVELS{1,2}), pvm_perror('mmclose'), return, end
  if pvm_delinfo('MMLEVELS',0,0), pvm_perror('mmclose'), return, end
							%%%%%%%%%%
 [info mbinfo] = pvm_getmboxinfo('PVMSTARTER');		% PVM down
  if info,			  pvm_perror('mmclose'), return, end
  if length(mbinfo)==0, return, end
  if mbinfo(1).owners~= pvm_mytid
			error('mmclose: inconsistencia PVMSTARTER'), end
  if pvm_halt,		pvm_perror('mmclose'), return, end
    
end

