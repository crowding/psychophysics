%PVM_GETFDS		sockets abiertos bajo PVM (ejemplo man pvm_getfds(3PVM))
%
%  [nfds fds] = pvm_getfds
%
%   nfds (int) número de descriptores
%        -14   PvmSysErr
%
%    fds (int array[nfds]) array de descriptores
%
%  Implementación MEX completa: src/pvm_getfds.c, pvm/MEX/pvm_getfds.mexlx

