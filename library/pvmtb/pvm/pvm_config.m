%PVM_CONFIG		Estado de la Máquina Virtual Paralela
%
%  [nhost narch hostinfo] = pvm_config
%
%  nhost (int) número de hosts en PVM
%        <0 código error
%       -14 PvmSysErr
%
%  narch (int) número de arquitecturas diferentes
%
%  hostinfo (array struct pvmhostinfo) información sobre hosts
%           tid		tids del pvmd
%           name	hostname
%           arch	arquitectura
%           speed	velocidad relativa
%
%  Implementación MEX completa: src/pvm_config.c, pvm/MEX/pvm_config.mexlx

