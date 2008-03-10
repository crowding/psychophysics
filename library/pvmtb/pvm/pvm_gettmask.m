%PVM_GETTMASK		Devuelve la máscara de traza de una tarea o sus hijas
%
%  [info mask]= pvm_gettmask('who')
%
%  who (string) 'Self'  para la propia tarea
%		'Child' para las tareas arrancadas a partir de ahora
%  mask(string) máscara de TEV_MASK_LENGTH (36) chars devuelta
%  info   (int) código de retorno
%      0 PvmOk
%     -2 PvmBadParam
%
%  Implementación MEX completa: src/pvm_gettmask.c, pvm/MEX/pvm_gettmask.mexlx

