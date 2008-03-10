%PVM_TRECV		Recibe un mensaje, crea buffer recepción. Con timeout.
%
%  bufid = pvm_trecv(tid, msgtag, tmout)	* tid, bufid: int * tmout: real
%
%  tid    (int) identificador de la tarea que envía. -1 para cualquiera
%  msgtag (int) código del mensaje >=0. -1 para cualquiera
%  tmout (real) tiempo máximo de espera (unidad secs, precisión usecs)
%               0 como pvm_nrecv       (probe-return)
%              [] como pvm_recv        (esperar indefinidamente)
%  bufid (int) <0 código de estado
%      >0 nuevo buffer recepción
%       0 PvmOk (pasó el tmout sin recibirse mensaje)
%      -2 PvmBadParam
%     -14 PvmSysErr
%
%  Implementación MEX completa: src/pvm_trecv.c, pvm/MEX/pvm_trecv.mexlx

