%PVM_HALT		Mata PVM, ver página manual     man pvm_halt(3PVM)
%
%  info = pvm_halt
%
%  info (int) código de retorno
%       0 PvmOk
%     -14 PvmSysErr
%			Se ignora SIGTERM, se llama a pvm_exit (acabar bien)
%
% Implementación MEX completa: src/pvm_halt.c, pvm/MEX/pvm_halt.mexlx

