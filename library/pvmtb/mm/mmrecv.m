function [srcinum, names] = mmrecv(varargin)
%MMRECV		Recibe variables Matlab de instancia MM
%
%  [srcinum names] = mmrecv [ ( [inum [,tmout]]  [,'vnam']... ) ]
%
%  inum (int)	Número de instancia MM de la que se desea recibir
%	-1 si cualquier instancia es aceptable como origen (default)
%
%  tmout (real)	Tiempo máximo a esperar las variables (usa pvm_trecv)
%		Unidades de segundos, resolución de usecs
%	+Inf para esperar indefinidamente (usa pvm_recv, bloqueante, default)
%	   0 para no esperar (usa pvm_nrecv, no bloqueante)
%
%  vnam (string) Nombres deseados para las variables recibidas
%
%  srcinum (int) número de la instancia MM origen del mensaje 
%		 0 si no llega ninguna variable a tiempo
%		-1 si error
%
%  names (cellstr) Nombres originales de las variables recibidas
%		 {} si no llega ninguna (tmout<Inf), ó error
%
%	Ver también: mmsend, mmcast, mmreduce, mmscatter, mmgather

srcinum=-1; names={};						%%%%%%%%%%
inum =-1; tmout=Inf; newnames={};				% defaults
								%%%%%%%%%%
if ~pvme_is,error('mmsend: no hay sesión PVM arrancada'), end	% stat chk
if ~mmis,   error('mmsend: no hay sesión MM  arrancada'), end	%%%%%%%%%%

if   length(varargin) & isnumeric(varargin{1}) &...		%%%%%%%%%
			   length(varargin{1})==1		% arg chk
      inum =varargin{1};          varargin(1)=[];		%%%%%%%%%
  if length(varargin) & isnumeric(varargin{1}) &...
			   length(varargin{1})==1
      tmout=varargin{1};          varargin(1)=[];
end,end
if   length(varargin) & iscellstr(varargin)
   newnames=varargin;             varargin   ={};
end
if length(varargin),	error('mmrecv: argumentos mal'), end

[level, ctx, mmids, grpnam] = mmlevel;
if inum==-1, tid=-1;						%%%%%%%%%
else,	tid = pvm_gettid(grpnam, inum);				% sem chk
     if tid==-1,	error('mmrecv: inum erróneo'), end	%%%%%%%%%
end

TAGMSG=667;							%%%%%%
switch tmout							% RECV
case Inf							%%%%%%
	bufid = pvm_recv (tid, TAGMSG);
	if bufid <0, srcinum=bufid; pvm_perror('mmrecv'), return, end
case 0
	bufid = pvm_nrecv(tid, TAGMSG);
	if bufid <0, srcinum=bufid; pvm_perror('mmrecv'), return, end
	if bufid==0,		    disp ('pvm_nrecv: no hay mensaje'), end
otherwise
	bufid = pvm_trecv(tid, TAGMSG, tmout);
	if bufid <0, srcinum=bufid; pvm_perror('mmrecv'), return, end
	if bufid==0,		    disp ('pvm_trecv: tiempo expirado'), end
end

if bufid==0, srcid=0; return, end				%%%%%%%%
%  bufid >0							% UNPACK
								%%%%%%%%
[info binfo] = pvm_bufinfo(bufid);
	if info, srcinum=info;	pvm_perror('mmrecv'), return, end
   srcinum = pvm_getinst(grpnam, binfo.tid);
	if srcinum<0,		pvm_perror('mmrecv'), return, end
[info names] = pvm_unpack(newnames{:});
	if any(info),srcinum=info;pvm_perror('mmrecv'), return, end

if isempty(newnames), newnames=names; end
for i = 1:length(newnames)
	assignin('base', newnames{i}, eval(newnames{i})), end

