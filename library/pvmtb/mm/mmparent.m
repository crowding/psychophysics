function tid = mmparent
%MMPARENT	Devuelve identificador(PVM) de instancia MM madre
%
%  tid = mmparent
%
%  tid (int) Identificador PVM de la instancia que arrancó a la que llama
%     >0		tid del padre
%     [ ]		si no tiene padre
%
%	Ver también: mmis, mmlevel, mmlevels, mmmyid

tid = [];

if ~pvme_is,	error('mmparent: no hay sesión PVM arrancada'), end
if ~mmis,	error('mmparent: no hay sesión MM  arrancada'), end

tid = pvm_parent;

if tid==-23,	tid = [];
	if (~isempty(getenv('PVMEPID')))
		error('mmparent: inconsistencia PVMEPID/pvm_parent'), end
elseif tid>0
	if ( isempty(getenv('PVMEPID')))
		error('mmparent: inconsistencia PVMEPID/pvm_parent'), end
else,		pvm_perror('mmparent'), end

