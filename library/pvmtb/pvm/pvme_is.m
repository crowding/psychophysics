function f = pvme_is()
%PVME_IS		Devuelve 0 si no hay PVM en ejecución, 1 si lo hay
%
%  f = pvme_is
%		Consiste en llamar a pvm_mstat(hostname)
%		'hostname()' necesita crear un fichero temporal (/tmp)
%
%  Implementación M total

% if pvm_mstat(hostname)==0, f=1; else, f=0; end	% Debería poner PvmOk
   f=pvm_mytid>0;

