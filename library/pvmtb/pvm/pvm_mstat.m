%PVM_MSTAT		Estado de una máquina bajo PVM
%
%  mstat = pvm_mstat ('host')
%
%  host(string) nombre de las máquina
%  mstat  (int) información de estado
%        0  PvmOk       El host funciona
%       -6  PvmHoHost   El host no pertenece a PVM
%      -22  PvmHostFail El host no funciona
%      -14  PvmSysErr   falla el PVMd local
%
%  Implementación MEX completa: src/pvm_mstat.c, pvm/MEX/pvm_mstat.mexlx

