function [level, ctx, mmids, grpnam] = mmlevel(dst_level)
%MMLEVEL	Salta a nivel aleatorio de sesión MM
%
%  [level ctx mmids grpnam] = mmlevel [ (dst_level) ]
%
%	Se salta al nivel indicado si se especifica y existe
%	Se devuelven el nivel resultante y los datos PVM asociados,
%		(contexto, tids de las instancias, y nombre de grupo)
%	Si no se salta, serán los mismos que previamente
%
%	Nivel 0 equivale a salirse del sistema de niveles
%
%	Se actualiza anotación level en mbox
%	Instancias MM hijas sólo pueden consultar, no saltar de nivel
%
%	Ver también: mmis, mmlevels, mmmyid, mmparent

level = 0;
ctx   = 0;							%%%%%%%%%%
mmids =[];							% defaults
grpnam='';							%%%%%%%%%%
								% stat chk
if ~isempty (getenv ('PVMEPID')) & nargin			%%%%%%%%%%
		error('mmlevel: no saltar desde instancia Matlab hija'), end
if ~pvme_is,	error('mmlevel: no hay sesión PVM arrancada'), end
if ~mmis,	error('mmlevel: no hay sesión MM  arrancada'), end

[level MMLEVELS MMGRPMAX] = mmlevels;

if ~nargin, ctx    = MMLEVELS{level+1, 1};			%%%%%%%%%
	    mmids  = MMLEVELS{level+1, 2};			% arg chk
	    grpnam = MMLEVELS{level+1, 3};	return		%%%%%%%%%

elseif ~isnumeric(dst_level)
		error('mmlevel: nivel debe ser numérico'), end

if (dst_level<0) | (dst_level+1>size(MMLEVELS,1))
		error('mmlevel: nivel destino no existe'), end
								%%%%%%%
%=== LEVEL ===							% LEVEL
   old_ctx = pvm_getcontext;					%%%%%%%
if old_ctx~= MMLEVELS{level+1, 1}
		error('mmlevel: inconsistencia nivel/ctx'), end
     level = dst_level;
       ctx = MMLEVELS{level+1, 1};
     mmids = MMLEVELS{level+1, 2};
    grpnam = MMLEVELS{level+1, 3};
if old_ctx~= pvm_setcontext(ctx)
		error('mmlevel: inconsistencia pvm_setcontext'), end

putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX);
%=== LEVEL ===						%%%%%%%%%%%%%%%%%%
							% Join grupo nivel
if level						%%%%%%%%%%%%%%%%%%
     inum = pvm_getinst(grpnam, pvm_mytid);
  if inum>0, error('mmlevel: inconsistencia pvm_getinst'), end
  if inum<0, pvm_perror('mmlevel'), return, end
end

