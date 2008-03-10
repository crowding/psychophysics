function info = mmis()
%MMIS		Comprueba si hay sesión MM
%
%  info = mmis
%
%  info	0 Si no está arrancado PVM ó no se ha usado mmopen aún
%	1 Si ya se ha usado mmopen (se comprueba mbox MMLEVELS)
%
%	Ver también:	mmlevel, mmlevels, mmmyid, mmparent

if ~pvme_is, info=0; return, end

[info mbinfo] = pvm_getmboxinfo('MMLEVELS');
if info,info=	0;			% PvmOk==0
else,	info=length(mbinfo);		% debe haber sólo 1 anotación MMLEVELS
end

