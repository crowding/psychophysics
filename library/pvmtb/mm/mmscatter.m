function info = mmscatter(porcion, var)
%MMSCATTER	Reparte variable Matlab entre las instancias del nivel
%
%  info = mmscatter(porcion, var)
%
%  porcion	variable Matlab a recibir la porción correspondiente
%
%  var	en la instancia madre, variable Matlab a repartir
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
%	Desde la instancia madre se reparte var
%	Matlab almacena columnwise (último índice el más rápido)
%
%	Ver también: mmsend, mmrecv, mmcast, mmreduce, mmgather

								%%%%%%%%%%
info=-1;							% defaults
if ~pvme_is,	error('mmscatter: PVM no está arrancado'), end	%%%%%%%%%%
if ~mmis,	error('mmscatter: MM  no está arrancado'), end	% stat chk
								%%%%%%%%%%
if nargin<2,	error('mmscatter: se requieren 2 args'), end	%%%%%%%%%
[level, ctx, mmids, grpnam] =  mmlevel;				% arg chk
if isempty(mmids)						%%%%%%%%%
		error('mmscatter: nadie con quien repartir'),end% sem chk
								%%%%%%%%%
TAGMSG=667;							% SCATTER
info  = pvm_scatter(porcion, var, TAGMSG, grpnam, 0);		%%%%%%%%%

