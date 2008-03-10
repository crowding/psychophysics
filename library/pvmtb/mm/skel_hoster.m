function info = skel_hoster(bufid)
%SKEL_HOSTER		Manejador mensajes SM_STHOST
%
%	Pensado para instalarlo con pvm_addmhf(src,tag,ctx, 'skel_hoster')
%		por ejemplo: pvm_addmhf(-1, -2147221489, 0, 'skel_hoster')
%		como todo manejador, acepta bufid, da igual retorno
%
%	En este esqueleto sencillamente se responde que no se arranca nada
%		pero se imprime el mensaje y se responde SM_STHOSTACK
%
%	Datos tomados de $PVM_ROOT/include/pvm3.h
%
% #define PvmDataDefault  0               /* XDR encoding */
% #define PvmDataFoo PvmDataDefault       /* Internal use */
% #define PvmResvTids    11 /* allow reserved message tids and codes */
%
%
%	Datos tomados de $PVM_ROOT/include/pvmproto.h
%
% #define SM_FIRST        (int)0x80040001 /* first SM_ message */
% #define SM_STHOST       (SM_FIRST+14)   /* d->H start slave pvmds */
% #define SM_STHOSTACK    (SM_FIRST+15)   /* H->d like DM_STARTACK */
%
%	0x80040001 = -2147221503 = SM_FIRST
%	0x8004000F = -2147221489 = SM_STHOST
%	0x80040010 = -2147221488 = SM_STHOSTACK
%
%	Datos tomados de pág man pvm_reg_hoster
%
%	The format of the SM_STHOST message is:
%	int nhosts                // number of hosts
%	{	int tid           // of host
%		string options    // from hostfile so= field
%		string login      // in form ``[username@]hostname.domain''
%		string command    // to run on remote host
%	} [nhosts]
%
%	The format of the reply message is:
%	{	int tid           // of host, must match request
%		string status     // result line from slave or error code
%	} []
%

info = 0;
PvmDataFoo  =  0;			% Constantes PVM
PvmResvTids = 11;
SM_STHOST   =-2147221489;
SM_STHOSTACK=-2147221488;

  [info minfo] = pvm_getminfo(bufid);
     if minfo.tag~=SM_STHOST
	error('skel_hoster: me llega mensaje que no es SM_STHOST'), end
FROMTID=minfo.src;			% sacar fuente
WID    =minfo.wid;			% sacar wid

[info nhost]=pvm_upkint;
fprintf('skel_hoster: mensaje SM_STHOST: arrancar %d hosts\n',nhost);
pvm_setopt  (PvmResvTids,1);
pvm_initsend(PvmDataFoo);
pvm_pkint   (nhost);

for i=1:nhost
  [info tid]=pvm_upkint;
  [info so ]=pvm_upkstr;
  [info log]=pvm_upkstr;
  [info cmd]=pvm_upkstr;
  fprintf('skel_hoster: tid=%x, so=%s, login=%s\n',tid,so,log);
  fprintf('skel_hoster: cmd=%s\n',cmd);

  pvm_pkint(    tid     );		% respuesta sobre cada uno
  pvm_pkstr('PvmDSysErr');
end

disp('skel_hoster: respondiendo que no podemos en SM_STHOSTACK');
       bufid = pvm_getsbuf;
[info  minfo]= pvm_getminfo(bufid);	% copiar el wid
       minfo.wid = WID;
pvm_setminfo(bufid,   minfo);

pvm_send  (FROMTID, SM_STHOSTACK);	% responder
pvm_setopt(PvmResvTids,        0);

