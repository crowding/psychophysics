function info = mmsend(inums, varargin)
%MMSEND		Envia variables Matlab a algunas instancias MM del nivel
%
%  info = mmsend(inums, var [,var]...)
%
%  inums(int/arr) Números de instancia a las que mandar las variables
%		si incluye a la que llama, se le manda con pvm_send
%
%	En general se utiliza pvm_mcast para enviar sólo a las otras
%
%  var		Cualesquiera variables Matlab
%
%	Ver también: mmrecv, mmcast, mmreduce, mmscatter, mmgather

								%%%%%%%%%%
info=-1;							% defaults
if ~pvme_is, error('mmsend: no hay sesión PVM arrancada'), end	%%%%%%%%%%
if ~mmis,    error('mmsend: no hay sesión MM  arrancada'), end	% stat chk
								%%%%%%%%%%
if isempty(varargin),	error('mmsend: nada para enviar'), end	% arg chk
[lvl ctx mmids grpnam] = mmlevel;				%%%%%%%%%
tids = pvm_gettid(grpnam, inums);				% sem chk
bad  = find(tids<0);						%%%%%%%%%
if ~isempty(bad),	tids(bad)=[];
	warning(['mmsend: inums erróneos: ' int2str(inums(bad))] ), end
if isempty(tids),	error  ('mmsend: nadie a quien enviar'), end

metoo = find(tids==pvm_mytid);
if isempty(metoo),		metoo=0;
	else,	tids(metoo)=[]; metoo=1; end

TAGMSG=667;							%%%%%%
info =	pvm_initsend;						% SEND
	if info<0,	pvm_perror('mmsend'), return, end	%%%%%%
info =	pvme_pack(varargin{:});
	if info,	pvm_perror('mmsend'), return, end

if ~isempty(tids)						% remote
	info = pvm_mcast(tids,TAGMSG);				%%%%%%%%
	if info,	pvm_perror('mmsend'), return, end
end
if metoo							% local
	info = pvm_send(pvm_mytid,TAGMSG);			%%%%%%%
	if info,	pvm_perror('mmsend'), return, end
end

