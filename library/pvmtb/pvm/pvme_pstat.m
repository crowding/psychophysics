function stat = pvme_pstat(tid)
%PVME_PSTAT		Estado de un proceso bajo PVM
%
%  stat = pvme_pstat(tid)	* extensión para arrays de pvm_pstat
%

if ~isnumeric(tid),	error('se requiere arg numérico'), end

stat=zeros(size(tid));			% Preallocate
for i=1:length(stat)
  stat(i)=pvm_pstat(tid(i));
end

