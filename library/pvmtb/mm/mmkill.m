function info = mmkill(inums)
%MMKILL		Mata instancias MM (Matlab)
%
%  info = mmkill(inums)
%
%  inums (int/array) números de instancia MM
%
%  info  (int/array) Códigos de retorno PVM
%
%	Ver también: mmopen, mmclose, mmup, mmdown, mmexit

info = -1;							%%%%%%%%%%
    if ~pvme_is,error('mmkill: no hay sesión PVM arrancada')	% stat chk
elseif ~mmis,	error('mmkill: no hay sesión MM  arrancada')	%%%%%%%%%%
else
  if any(inums==0)						%%%%%%%%%
		error('mmkill: no se puede matar madre'), end	% arg chk
 [level ctx mmids grpnam] = mmlevel;				%%%%%%%%%
  kids = pvm_gettid(grpnam, inums);				% sem chk
  kf   = find(kids<0);						%%%%%%%%%
  if ~isempty(kf)
		disp(['instancia MM #'	int2str(inums(kf))])
		disp(['PVM tids #'	int2str(kids (kf))])
		warning('mmkill: no existe'),   kids (kf)=[]; end
					
  if isempty(kids)
		warning('mmkill: nada para matar'), end	% se confía que notify
							% borre mmids-tids
  info=pvm_kill(kids); end
end

