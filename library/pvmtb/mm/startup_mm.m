function info = startup_mm
%STARTUP_MM		Script para arrancar tareas MM (uso interno)
%
%	Pensado para llamarlo desde startup.m al arrancar,
%		si es tarea MM/PVM hija (comprobar PVMEPID)
%	Hecho function para evitar clear -> workspace propio
%	Observar que pvm_siblings es la primera llamada PVM
%		llamando una segunda vez ya no funciona
%		oportuno para enforzar uso interno (sale error si no)

if isempty(getenv('PVMEPID'))
		      error('startup_mm: uso interno'), end

disp('Arrancando instancia Matlab hija ...')

[info SIBLINGS]=pvm_siblings
if info<0,	pvm_perror('startup_mm')
		error('startup_mm: uso interno: pvm_siblings'), end

if ~mmis,disp('startup_mm: no parece arrancado con mmspawn'), return,end

[level ctx mmids grpnam] = mmlevel;
if ~level
	disp('startup_mm: no parece arrancado con mmspawn')
else % level						%%%%%%%%%%%%%%%%%%%%%%
							% Join grupo del nivel
  info =pvm_joingroup(grpnam);				%%%%%%%%%%%%%%%%%%%%%%
	if info==0,	error('startup_mm: inconsistencia pvm_joingroup'), end
	if info <0,	pvm_perror('startup_mm'), return, end

  TAGPWN=665;
  info =pvm_recv(pvm_parent, TAGPWN);		% bufid en realidad
	if info<0,	pvm_perror('startup_mm'), return, end
  info =pvm_unpack;
	if any(info),	pvm_perror('startup_mm'), return, end

  if ~exist('Wd',   'var') |...
     ~exist('Try',  'var') |...
     ~exist('Catch','var')
	info=-1; error('startup_mm: no encuentro entorno MMSPAWN'), end

  disp('Ajustando atributos instancia MM...')
  if exist(Wd, 'dir'),	cd(Wd)
		else,	disp(['startup_mm: no puedo cd ' Wd]), end
  if isempty(Catch),	eval(Try)
		else,	eval(Try,Catch), end

end	% else level

