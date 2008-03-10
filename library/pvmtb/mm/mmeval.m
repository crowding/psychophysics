function [info, retval] = mmeval(varargin)
%MMEVAL		Envia comando Matlab a todas las instancias del nivel MM
%
%  [info retval] = mmeval(cmd [, 'metoo'] [, retnms])
%
%  cmd (string)	Comando Matlab a evaluar en todas las instancias del nivel
%     (cellstr)	Cell array con tantos Comandos Matlab como instancias
%		Se le manda un Comando a cada instancia del nivel
%
%  metoo (int)	0 -> la instancia madre no evalúa (default)
%		1 -> la instancia madre también evalúa el Comando
%		  (si sólo hay 1) ó entra en el reparto (si hay varios)
%
%  retnms	Cell array con los nombres de variable a devolver
%     (cellstr)		default: {'ans'}, común a todas las instancias
%
%  info   (int)	Código de error total (antes de tener ningún retval)
%     (cellnum)	Códigos de retorno (0==Ok), paralelo a retval
%		  diversas causas: PVM, evalin(base), undefined var...
%
%  retval(cell)	Cell array con los resultados de las evaluaciones
%
%	Internamente se utiliza pvm_bcast para enviar al grupo 1 comando
%				pvm_send  para enviar comandos distintos
%				eval/evalin('base') para evaluar localmente
%
%	Ver también: mmspawn, startup_mm, prompt_mm, prompt_catch

info  = -1;							%%%%%%%%%%
retval= { };							% defaults
metoo =  0;							%%%%%%%%%%
retnms= {'ans'};

if ~pvme_is,error('mmeval: no hay sesión PVM arrancada'), end	%%%%%%%%%%
if ~mmis,   error('mmeval: no hay sesión MM  arrancada'), end	% stat chk
if ~isempty(getenv('PVMEPID'))					%%%%%%%%%%
		error('mmeval: una MM hija no puede mmeval'), end
[level ctx mmids grpnam] = mmlevel;
if ~level,	error('mmeval: no hay hijas MM en nivel 0'), end

if ~nargin,	error('mmeval: especificar comando'), end	%%%%%%%%
if  nargin>3,	error('mmeval: demasiados args'), end		% argchk

cmd = varargin{1}; varargin(1)=[];				%%%%%%%%%%%%
if ~ischar(cmd) & ~iscellstr(cmd)				% cmd argchk
		error('mmeval: comando debe ser string ó cellstr'), end
if isempty(cmd) | (iscellstr(cmd) & any(cellfun('isempty',cmd)))
		error('mmeval: comando debe ser no vacío'), end

if    length   (varargin)					%%%%%%%%%%%%%%%
 if   ischar   (varargin{1})					% metoo  argchk
   metoo=strcmp(varargin{1},'metoo');	varargin(1)=[]; end	% retnms argchk
 if   length   (varargin)
  if  iscellstr(varargin{1})
	retnms= varargin{1};		varargin(1)=[]; end
  if ~isempty  (varargin), error('mmeval: arg#2,3 tipo mal'), end
  if  isempty(retnms) | any(cellfun('isempty',retnms))
		error('mmeval: string vacío en arg#3'), end
 end
end

if isempty(mmids) & ~metoo					%%%%%%%%%
	error('mmeval: no hay instancias donde evaluar'), end	% sem chk

TAGCMD=666;							%%%%%%%%%%%%%
MM_RETNMS=retnms;						% REMOTE EVAL
if ~isempty(mmids)
						%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if ischar(cmd),	MM_CMD = cmd;		% single cmd -> pvm_bcast

    info =pvm_initsend;
	if info<0,	pvm_perror('mmeval'), return, end
    info =pvme_pack(MM_CMD, MM_RETNMS);
	if info,	pvm_perror('mmeval'), return, end
    info =pvm_bcast(grpnam, TAGCMD);
	if info,	pvm_perror('mmeval'), return, end

  else	% ~ischar(cmd)				%%%%%%%%%%%%%%%%%%%%%%%%%%
						% multiple cmd -> pvm_send
    if length(cmd) ~= length(mmids)+metoo
		error('mmeval: #instancias ~= #comandos'), end

    bad=[];
    for i = 1:length(mmids)	% BUG: si fallo parcial, esperar respuesta
				% sólo de los que recibieron bien
      info=pvm_initsend;
	if info<0,	pvm_perror('mmeval'), bad(end+1)=i; else    %   1 %%%
			MM_CMD = cmd{i+metoo};
      info =pvme_pack(	MM_CMD, MM_RETNMS);
	if info,	pvm_perror('mmeval'), bad(end+1)=i; else    % 2   %%%
      info =pvm_send(mmids(i), TAGCMD);
	if info,	pvm_perror('mmeval'), bad(end+1)=i; end
							    end,end % 2 1 %%%
    end	% for length(mmids)
    mmids(bad)=[];
						% multiple
  end	% else ~ischar(cmd)			%%%%%%%%%%%%%%%%%%%%%%%%
								% REMOTE
end	% if ~isempty(mmids)					%%%%%%%%

info={}; inf0=0;				% asumir Ok por defecto

if metoo				% aprovechar tiempo espera resultados
	info{1}=[];	retval{1}={};
    if ischar(cmd),	MM_CMD = cmd    ;		%%%%%%%%%%%%%%%%%
	else,		MM_CMD = cmd {1};	end	% LOCAL EVAL/RECV
    evalin ('base',	MM_CMD, 'inf0=-1;');		%%%%%%%%%%%%%%%%%
    if  inf0,		disp([char(7) 'MM_CMD??? ' lasterr]), end
    for n=retnms
	info{1}(end+1) = -1+evalin('base', ['exist(''' n{1}  ''',''var'')'] );
    if ~info{1}(end),	retval{1}{end+1}=evalin('base',n{1});
		else,	retval{1}{end+1}=[];     end
    end	% for retnams
end	% if metoo
					% info se usa para devolver retcode
					% inf0 mejor para cmd status
for i=1:length(mmids)						%%%%%%%%%%%%%
								% REMOTE RECV
   info{i+metoo}=[];	retval{i+metoo}={};			%%%%%%%%%%%%%
   inf0=pvm_recv(mmids(i), TAGCMD);
	if inf0<0,	pvm_perror('mmeval'), info{i+metoo}=inf0; else % 1 %%%
  [inf0 names]=pvm_unpack;
	if inf0,	pvm_perror('mmeval'), info{i+metoo}=inf0;
elseif length(names)~=length(retnms)
	warning('mmeval: #vars retorno mal'), info{i+metoo}=  -1; else % 2 %%%

    if	any(cellfun('length',names)~=cellfun('length',retnms)) |...
	any(                [names{:}]~=             [retnms{:}])
	warning('mmeval: varnames retorno mal'), end

      for n=retnms
	info{i+metoo}(end+1) = -1+exist(n{1}, 'var');
    if ~info{i+metoo}(end),	retval{i+metoo}{end+1}= eval(n{1});
			else,	retval{i+metoo}{end+1}= [];     end
      end	% for retnams
  end,end	% else 2 1 %%%
end		% for i

