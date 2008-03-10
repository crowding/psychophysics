function info = startup_Users99
%STARTUP_USERS99	Script para arrancar tareas MM (uso interno)
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

% [info SIBLINGS]=pvm_siblings;
% if info<0,	pvm_perror('startup_mm')
%		error('startup_mm: uso interno: pvm_siblings'), end

TAG=7; RAW=1;
cd matlab/images

hostname
pvm_recv(pvm_parent,TAG); pvm_unpack;		% Se espera variable NUMCMDS
disp('Recibido nº comandos')
pvm_initsend(RAW); pvme_pack(NUMCMDS,QUIT);	% y flag QUIT=0/1
pvm_send(pvm_parent,TAG);			% Responder mensaje acknowledge
disp('Respuesta de reconocimiento')

for indiceBuclePVM=1:NUMCMDS			% Bucle de respuesta
  indiceBuclePVM
  pvm_recv(pvm_parent,TAG); pvm_unpack; eval(cmd);
end

if QUIT, quit, end				% Si se indicó salir, hacerlo

