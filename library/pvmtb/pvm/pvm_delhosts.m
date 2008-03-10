%PVM_DELHOSTS		Quita hosts de la máquina virtual PVM
%
%  [numh infos] = pvm_delhosts('host' [,'host']...)
%
%  host (string)nombres de los hosts a eliminar (al menos 1)
%  numh (int)	número de hosts realmente quitados
%      ==nhost	éxito total
%        0	ver infos
%
%  infos (int array[nhost]) información de estado
%         si hubo error parcial, estado puede ser código error
%	  0	PvmOk
%	 -2	PvmBadParam
%	-14	PvmSysErr
%
%  Implementación MEX completa: src/pvm_delhosts.c, pvm/MEX/pvm_delhosts.mexlx

