function info = quithandler_mm(bufid)
%QUITHANDLER_MM		Manejador salida tareas MM (uso interno)
%
%	Pensado para instalarlo desde mmopen.m al arrancar MM,
%		y desinstalarlo desde mmclose.m al acabar MM
%	El mhid se guarda en el campo mmids del nivel 0, MMLEVELS{1,2}
%		es común a todos los niveles
%
%	A su vez, mmspawn encarga pvm_notify(TaskExit) de cada MM arrancada
%	Cuando sale una tarea, PVM envía notificación
%	En la madre MM#0, se debe hacer pvm_probe(-1,-1) para disparar
%		el manejador (típicamente antes de leer MMLEVELS)
%
%	El manejador deja anotada variable entorno MM_NTFY=ctx mmid
%		madre lo detecta cuando use mmlevels.m (consulta mbox)
%		borra la tarea MM del campo mmids del nivel MM asociado
%

info = -1;
if ~isempty(getenv('PVMEPID'))
		error('quithandler_mm: uso interno madre MM'), end
if pvm_mytid<0,	error('quithandler_mm: no hay sesión PVM arrancada'), end

[info minfo]=pvm_getminfo(bufid);
	if info,pvm_perror('pvm_getminfo'), error(' '), end
[info msg]=pvme_upkntfy;
	if info,pvm_perror('pvme_upkntfy'), error(' '), end

disp('Detectada salida de instancia MM hija');
putenv( [ 'MM_NTFY=' int2str(minfo.ctx) ' ' int2str(msg) ] );	
				% aquí no se puede pvm_recvinfo, putinfo

