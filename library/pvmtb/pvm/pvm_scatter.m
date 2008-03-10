%PVM_SCATTER		Reparte una variable Matlab entre varias instancias
%
%  info = pvm_scatter(porcion, var, msgtag, 'group', inst)
%
%  porcion	variable Matlab a recibir la porción correspondiente
%
%  var	en la instancia origen indicada, variable Matlab a repartir
%	en otras instancias no se usa su valor
%
%  msgtag   (int) tag deseado para los mensajes de scatter
%  group (string) nombre del grupo sobre cuyos elementos se reparte
%  inst     (int) instancia del grupo desde la que se reparte
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
%	Desde la instancia indicada se reparte var
%	Matlab almacena columnwise (último índice el más rápido)
%	Las variables porcion no tienen que ser de las mismas dimensiones
%	 pero sí del mismo tamaño, tipo y complejidad
%
%	El tamaño y tipo de datos a enviar se deduce de la variable porcion
%	Si es compleja, la parte compleja se reparte después de la real
%
%  Implementación MEX completa: src/pvm_scatter.c, pvm/MEX/pvm_scatter.mexlx

