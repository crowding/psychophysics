%PVM_GATHER		Reune variables Matlab de varias instancias en una sola
%
%  info = pvm_gather(var, porcion, msgtag, 'group', inst)
%
%  porcion	variable Matlab a juntar con otras
%
%  var	en la instancia destino indicada, variable Matlab para la recolección
%	en otras instancias no se usa su valor
%
%  msgtag   (int) tag deseado para los mensajes de gather
%  group (string) nombre del grupo sobre cuyos elementos se recolecta
%  inst     (int) instancia del grupo en donde se recolecta
%
%  info (int) código de retorno
%	-21 PvmNoInst
%	 -2 PvmBadParam
%	-14 PvmSysErr
%
%	Se espera que todas las instancias del grupo hagan
%	 la misma llamada colectivamente, coincidiendo todos los
%	 argumentos salvo tal vez las variables porcion/var
%
%	A la instancia indicada se envían todas las porciones
%	Matlab almacena columnwise (último índice el más rápido)
%	Las variables porcion no tienen que ser de las mismas dimensiones
%	 pero sí del mismo tamaño, tipo y complejidad
%
%	El tamaño y tipo de datos a enviar se deduce de la variable porcion
%	Si es compleja, la parte compleja se envia después de la real
%
%  Implementación MEX completa: src/pvm_gather.c, pvm/MEX/pvm_gather.mexlx

