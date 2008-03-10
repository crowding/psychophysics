%PVM_START_PVMD		Arranque daemon PVMD, ver página man pvmd(1PVM)
%
%  info = pvm_start_pvmd({ ['arg' [,'arg']... ] }, block)
%
%  args (cell array strings) argumentos, uno por línea, [-options] [hostfile]
%       -options: -dmask -nname -s -S -f 
%        hostfile _no_ se busca en el Matlab path, hay que dar path
%  block (int) modo de bloqueo
%        0 retorna inmediatamente
%      !=0 retorna tras añadir con éxito los hosts
%
%  info  (int) código de retorno
%        0 PvmOk
%      -28 PvmDupHost
%      -14 PvmSysErr
%
%  Implementación MEX completa: pvm_start_pvmd.c, pvm_start_pvmd.mexlx

