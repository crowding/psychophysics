function tids = pvme_gids(group)
%PVME_GIDS		TIDS de todas las instancias en un grupo
%
%  tids = pvme_gids('group')
%
%  group (string) nombre del grupo
%  tids  (int[])  array con los TIDs
%
%  Implementación M total

    if  nargin==0,     error('se requiere 1 arg')
elseif ~ischar(group), error('se requiere 1 arg string'), end

ninst=pvm_gsize(group);
tids=zeros(1,ninst);				% Preallocate
for i=1:ninst,
  tids(i)=pvm_gettid(group,i-1);
end

