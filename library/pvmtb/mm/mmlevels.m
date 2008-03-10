function [level, MMLEVELS, MMGRPMAX] = mmlevels
%MMLEVELS	Devuelve la anotación de niveles MM en mailbox
%
% [level MMLEVELS MMGRPMAX] = mmlevels
%
%  level (int) nivel MM actual
%
%  MMLEVELS      (cell)	una fila por cada nivel: { ctxt [mmids] 'grpnam'}
%	ctx       (int)	contexto PVM asociado al nivel MM
%	mmids(intarray)	identificadores PVM de las instancias del nivel
%	grpnam (string)	nombre de grupo PVM asociado al nivel MM
%
%  MMGRPMAX (int) ültimo número de grupo usado, útil sólo para mmopen
%
%	Ver también: mmis, mmlevel, mmmyid, mmparent
%

level   = 0;
MMLEVELS={};							%%%%%%%%%
MMGRPMAX= 0;							% default
								%%%%%%%%%%
if ~pvme_is,error('mmlevels: no hay sesión PVM arrancada'), end % stat chk
if ~mmis,   error('mmlevels: no hay sesión MM  arrancada'), end %%%%%%%%%%

if pvm_recvinfo('MMLEVELS',0,0)<0
			pvm_perror('mmlevels'), return, end
if pvm_unpack,		pvm_perror('mmlevels'), return, end

if ~exist(   'level','var'),error('mmlevels: no encuentro mbox    level'), end
if ~exist('MMLEVELS','var'),error('mmlevels: no encuentro mbox MMLEVELS'), end
if ~exist('MMGRPMAX','var'),error('mmlevels: no encuentro mbox MMGRPMAX'), end

MM_NTFY = getenv ('MM_NTFY');
	unsetenv ('MM_NTFY');
    if  ~isempty  (MM_NTFY)
 [ctx mmid]=strtok(MM_NTFY);   ctx=str2num(ctx); mmid=str2num(mmid);

  levels = size(MMLEVELS,1);
  lv=1; while (lv<=levels) & (MMLEVELS{lv,1}~=ctx), lv=lv+1; end
  if (lv<2) | (lv> levels)
			error('mmlevels: no encuentro ctx MM_NTFY'), end
  idx = find(MMLEVELS{lv,2}==mmid);  if length(idx)~=1
			error('mmlevels: no encuentro mmid MM_NTFY'), end
  MMLEVELS{lv,2}(idx)=[];
		      fprintf('mmlevels: borrada tarea %d nivel %d\n',mmid,lv);
  if putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX)
			error('mmlevels: durante actualización MM_NTFY'), end
end

