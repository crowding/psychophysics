%PVM_ADDHOSTS		Añade hosts a la máquina virtual PVM
%
%  [numh infos] = pvm_addhosts('host' [,'host']...)
%
%  host (string)nombres de los hosts a añadir (al menos 1)
%  numh (int)  	número de hosts realmente añadidos
%       ==nhost(#elementos en hosts) éxito total
%	  0	ver infos
%	 -2	PvmBadParam
%	-30	PvmAlready
%	-14	PvmSysErr
%
%  infos (int array[nhost]) tids de los daemon PVMd arrancados
%        si hubo error parcial, algunos tids pueden ser códigos error
%	 -2	PvmBadParam
%	 -6	PvmNoHost
%	-29	PvmCantStart
%	-28	PvmDupHost
%	-26	PvmBadVersion
%	-27	PvmOutOfRes
%
%  Implementación MEX completa: src/pvm_addhosts.c, pvm/MEX/pvm_addhosts.mexlx

