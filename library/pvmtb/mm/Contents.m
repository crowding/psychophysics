% MM - Arranque/Finalización de Múltiples MATLAB bajo PVM
%
% Control del Sistema de Niveles
%   MMIS	Comprueba si hay sesión MM
%   MMOPEN	Crea nuevo nivel de sesión MM
%   MMCLOSE	Anula el nivel actual de sesión MM
%   MMUP	Sube a siguiente nivel de sesión MM
%   MMDOWN	Baja a nivel inferior de sesión MM
%   MMLEVEL	Salta a nivel aleatorio de sesión MM
%   MMLEVELS	Devuelve la anotación de niveles MM en mailbox
%
% Control de Instancias
%   MMSPAWN	Arranca nueva(s) instancia(s) MM
%   MMEXIT	Finaliza la instancia MM (Matlab) hija que llama
%   MMKILL	Mata instancias MM (Matlab)
%
% Información
%   MMMYID	Devuelve identificador(PVM) de esta instancia MM
%   MMPARENT	Devuelve identificador(PVM) de instancia MM madre
%
% Paso de Mensajes
%   MMEVAL	Envia comando Matlab a todas las instancias del nivel MM
%   MMSEND	Envia variables Matlab a algunas instancias MM del nivel
%   MMRECV	Recibe variables Matlab de instancia MM
%   MMCAST	Envia variables Matlab a todas las instancias MM del nivel
%   MMREDUCE	Reduce variable Matlab en la instancia MM madre
%   MMSCATTER	Reparte variable Matlab entre las instancias del nivel
%   MMGATHER	Reune variables Matlab de instancias hijas en madre
%
% Utilidades
%   ISCELLNUM True for cell array of numbers.
%   PUTMBOX		Secuencia initsend/pack/putinfo (uso interno)
%
% Uso interno
%   STARTUP_MM		Script para arrancar tareas MM (uso interno)
%   PROMPT_MM		Script intérprete para instancias MM (uso interno)
%   PROMPT_CATCH	Script para reanudación de instancias MM (uso interno)
%   QUITHANDLER_MM	Manejador salida tareas MM (uso interno)
%
% Pruebas de manejadores
%   SKEL_HOSTER		Manejador mensajes SM_STHOST
%   SKEL_TASKER		Manejador mensajes SM_STTASK
%   SKEL_RM		Manejador mensajes para Resource Manager
%   RM_INSTMHF		Pensado para instalar SKEL_RM como resource manager

