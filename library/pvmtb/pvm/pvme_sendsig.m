function info = pvme_sendsig(tid, signum)
%PVME_SENDSIG		Manda señal a tarea PVM
%
%  info = pvme_sendsig(tid, signum)	* extensión para arrays de pvm_sendsig
%

if ~isnumeric(tid)|...
   ~isnumeric(signum),	error('se requieren 2 args numéricos'), end

info=zeros(size(tid));			% Preallocate
for i=1:length(info)
  info(i)=pvm_sendsig(tid(i), signum);
end

