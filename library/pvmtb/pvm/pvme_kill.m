function info = pvme_kill(tid)
%PVME_KILL		Termina tarea PVM
%
%  info = pvme_kill(tid)	* extensión para arrays de pvm_kill
%

if ~isnumeric(tid),	error('se requiere arg numérico'), end

info=zeros(size(tid));			% Preallocate
for i=1:length(info)
  info(i)=pvm_kill(tid(i));
end

