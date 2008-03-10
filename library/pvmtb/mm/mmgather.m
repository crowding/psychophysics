function info = mmgather(var, porcion)
%MMGATHER	Reune variables Matlab de instancias hijas en madre
%
%  info = mmgather(var, porcion)
%
%  porcion	variable Matlab a juntar con otras
%
%  var	en la instancia madre, variable Matlab para la recolección
%	en otras instancias no se usa su valor (usar [], {}, '', 0...)
%
%  info (int) código de retorno
%	-21 PvmNoInst
%	 -2 PvmBadParam
%	-14 PvmSysErr
%
%	Se espera que todas las instancias del grupo hagan
%	 la misma llamada colectivamente
%
%	A la instancia indicada se envían todas las porciones
%	Matlab almacena columnwise (último índice el más rápido)
%
%	Ver también: mmsend, mmrecv, mmcast, mmreduce, mmscatter

								%%%%%%%%%%
info=-1;							% defaults
if ~pvme_is,	error('mmgather: PVM no está arrancado'), end	%%%%%%%%%%
if ~mmis,	error('mmgather: MM  no está arrancado'), end	% stat chk
								%%%%%%%%%%
if nargin<2,	error('mmgather: se requieren 2 args'), end	%%%%%%%%%
[level, ctx, mmids, grpnam] =  mmlevel;				% arg chk
if isempty(mmids)						%%%%%%%%%
		error('mmgather: nadie de quien recolectar'),end% sem chk
								%%%%%%%%%
TAGMSG=667;							% SCATTER
info  = pvm_gather(var, porcion, TAGMSG, grpnam, 0);		%%%%%%%%%

