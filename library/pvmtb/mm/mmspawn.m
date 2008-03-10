function mmids = mmspawn(varargin)
%MMSPAWN	Arranca nueva(s) instancia(s) MM
%	
%  mmids = mmspawn [ ( [config], ['attr','value']... ) ]
%
%	Todos los argumentos son opcionales
%	Se debe estar en nivel MM > 0
%	Cada nivel está aislado de los demás (respecto a mensajes PVM)
%
%  config  (cell) cell array (n,2) ó (n,1) con el siguiente formato
%		  { 'where' [ntask] [;
%		    'where' [ntask] ]... }
%		    la primera columna son strings
%		    la segunda es numérica, opcional
%		  Todo el cell array es opcional también,
%			si no se indica, equivale a {'~.', pvm_config-1}
%			se arranca 1 MM en cada host PVM salvo el actual
%		  Si se indica {}, equivale a {'~.', 1}
%		  Cada línea se trata con un pvm_spawn separado
%
%  where (string) dónde se arrancan (default ~.)
%	'*'				PVM escoge
%	'.' | 'local' | 'localhost'	host desde el que se llama
%	'~.'				en donde sea menos localhost
%	'ARCH'	('LINUX' | 'SUN4SOL2')	arquitectura concreta
%	'hostname'			host concreto
%
%  ntask    (int) número de instancias Matlab a arrancar (default 1)
%
%  Una instancia MM posee los siguientes atributos:
%	Atributo	Posibles valores	Valor por defecto
%	'Nice'		'std'| 'low'		'std'
%	'RunMode'	'fg' | 'bg'		'fg'
%	'Display'	'host:disp.scrn'	$DISPLAY actual
%	'Wd'		'/dir/subdir/...'	$CWD actual
%	'Try'		comando Matlab		'prompt_mm'
%	'Catch'		comando Matlab		'prompt_catch'
%
%  'Nice'	nivel de prioridad de la instancia
%  'RunMode'	fg es bajo xterm, bg es sin xterm, directamente
%  'Display'	destino de ventanas X11, N/A para bg
%  'Wd'		subdirectorio en que se arranca la instancia
%  'Try'/'Catch' son ejecutados mediante eval(Try,Catch)
%		en las instancias arrancadas, tras su inicialización
%
%	Ver también: mmeval, startup_mm, prompt_mm, prompt_catch

mmids   = [];							%%%%%%%%%
config  = {'~.'		pvm_config-1};				% default
where   =  '~.';	ntask   =  1 ;				%%%%%%%%%
Nice	= 'std';	RunMode =        'fg';	Display = getenv('DISPLAY');
Wd      =  pwd ;	Try     = 'prompt_mm';	Catch   =   'prompt_catch' ;

if ~pvme_is,error('mmspawn: no hay sesión PVM iniciada'), end	%%%%%%%%%%
if ~mmis,   error('mmspawn: no hay sesión MM  iniciada'), end	% stat chk
if ~isempty(getenv('PVMEPID'))					%%%%%%%%%%
		error('mmspawn: una MM hija no puede mmspawn'), end
if ~mmlevel,	error('mmspawn: usar pvm_spawn en nivel 0'), end

if nargin							%%%%%%%%%
  if ~iscellstr(varargin)					% arg chk
    config=varargin{1}; varargin(1)=[];				%%%%%%%%%
  end
  if ~iscellstr(varargin)	% sólo deben quedar #par strings o nada
    error('mmspawn: args atributos/valor deben ser strings'), end
  if mod(length(varargin),2)
    error('mmspawn: args atributos/valor deben estar por parejas'), end
end

if ndims(config)>2, error('mmspawn: config > 2 dims'), end	%%%%%%%%%%%%%
[lin col]=size(config); if ~lin, config={''}; end		% conf argchk
switch col							%%%%%%%%%%%%%
  case 2
  case 1,    config(:,2)=cell(lin,1);
  case 0,    config{1,2}=         [];
  otherwise, error('mmspawn: arg#1 > 2 columnas')
end
if ~iscellstr(config(:,1)),error('mmspawn: conf col#1 deben ser strings'), end
if ~iscellnum(config(:,2)),error('mmspawn: conf col#2 deben ser números'), end
col=find(cellfun('isempty',(config( : ,1))));
if ~isempty(col),          [config{col,1}]=deal(where), end
col=find(cellfun('isempty',(config( : ,2))));
if ~isempty(col),          [config{col,2}]=deal(ntask), end

while length(varargin) > 1				%%%%%%%%%%%%%%%%%
  attr=varargin{1}; val=varargin{2};			% attr/val argchk
  switch attr						%%%%%%%%%%%%%%%%%
    case 'Nice',	switch val
      case{'std','low'},Nice   = val; varargin(1:2)=[];
      otherwise,	val,error('mmspawn: Nice no reconocido')
      end
    case 'RunMode',	switch val
      case {'fg','bg'},	RunMode= val; varargin(1:2)=[];
      otherwise,	val,error('mmspawn: RunMode no reconocido')
      end
    case 'Display',	Display= val; varargin(1:2)=[];
    case 'Wd',		Wd     = val; varargin(1:2)=[];
    case 'Try',		Try    = val; varargin(1:2)=[];
    case 'Catch',	Catch  = val; varargin(1:2)=[];
    otherwise,		attr,error('mmspawn: atributo no reconocido')
  end	% switch
end	% while
							%%%%%%%%%%%%%%%%%%%%%%
							% Nice,RunMode,Display
   task='matlab'; args={'-display', Display};		% task/args setup %%%%
if RunMode=='fg'; args={args{:}, '-e', task};  task='xterm';  end
if Nice  =='low'; args={task,       args{:}};  task='nice'; end

TAGPWN=665;
% === SPAWN ===						%%%%%%%
for i = config'						% SPAWN
							%%%%%%%%%%%%%%%%%%%%%%%%
  where=i{1}; ntask=i{2}; switch where			% where/ntask/flag setup
    case '*',				flag = 0;	%%%%%%%%%%%%%%%%%%%%%%%%
    case{'.','local','localhost'},	flag = 1; where='.';
    case '~.',				flag =33; where='.';
    case {'LINUX','SUN4SOL2'},		flag = 2;
    otherwise,	if pvm_mstat(where)==0,	flag = 1;
		else flag=-1; where, warning('mmspawn: where no reconocido')
  end,		end
							%%%%%%%%%%%%%%%%%
							% arrancar tareas
  if flag>=0						%%%%%%%%%%%%%%%%%
    [numt ids]= pvm_spawn(task, args, flag, where, ntask);
    if numt<=0,	warning('mmspawn: no puedo pvm_spawn')
    else,
      if numt~=ntask, warning('mmspawn: error parcial pvm_spawn'), end
	ids = ids(1:numt);				%%%%%%%%%%%%%%%%%%%%%%
      mmids = [mmids ids];				% Pasar Try, Catch, Wd
	if pvm_initsend<0,		pvm_perror('mmspawn'), return, end
	if pvme_pack(Wd, Try, Catch),	pvm_perror('mmspawn'), return, end
	if pvm_mcast(mmids, TAGPWN),	pvm_perror('mmspawn'), return, end
    end % else numt<0
  end   % if flag
end     % for i = config'
% === SPAWN ===

if ~isempty(mmids)
  TAGTFY=668;
  if pvm_notify(1,TAGTFY,mmids), pvm_perror('mmspawn'), end

  [level, MMLEVELS, MMGRPMAX] = mmlevels;		%%%%%%%%%%%%%%%%%%%%%%%%
  ids = MMLEVELS{level+1, 2};  ids=[ids mmids];		% mmids -> mbox MMLEVELS
	MMLEVELS{level+1, 2} = ids;
  if putmbox('MMLEVELS', level, MMLEVELS, MMGRPMAX)
		pvm_perror('mmspawn'), return, end
 
  grpnam=MMLEVELS{level+1, 3};
  fprintf('mmspawn: esperando hijas MM...');		%%%%%%%%%%%%%%%%%%%%%%
  while length(pvme_gids(grpnam))~=length(ids), end	% Join grupo del nivel
  fprintf('hecho\n');

end % if ~isempty(mmids)

