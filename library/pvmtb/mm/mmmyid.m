function mmid = mmmyid()
%MMMYID		Devuelve identificador(PVM) de esta instancia MM
%
%	mmid = mmmyid
%
%  mmid (int) Identificador de instancia MM
%
%	Ver también: mmis, mmlevel, mmlevels, mmparent

mmid = -1;

if ~pvme_is,error('mmmyid: no hay sesión PVM arrancada'), end
if ~mmis,   error('mmmyid: no hay sesión MM  arrancada'), end

mmid = pvm_mytid; if mmid<0, pvm_perror('mmmyid'), end

