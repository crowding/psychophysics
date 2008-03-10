%PVM_REDUCE		Reduce variable Matlab de varias instancias a una sola
%
%  info = pvm_reduce('op', var, msgtag, 'group', inst)
%
%  op (string) operación de reducción deseada ('Max', 'Min', 'Sum', 'Product')
%
%  var	variable Matlab reducible: char,int8,int16,int32,single,double
%	no se pueden reducir: cell,struct,sparse,object,opaque
%
%  msgtag   (int) tag deseado para los mensajes de reducción
%  group (string) nombre del grupo sobre cuyos elementos se reduce
%  inst     (int) instancia del grupo sobre la que se reduce
%
%  info (int) código de retorno
%	-21 PvmNoInst
%	 -2 PvmBadParam
%	-14 PvmSysErr
%
%	Se espera que todas las instancias del grupo hagan
%	 la misma llamada colectivamente, coincidiendo todos los
%	 argumentos salvo tal vez la variable a reducir.
%
%	En la instancia indicada se recolecta el Máximo/Mínimo/Suma/Producto
%	 de los respectivos elementos de las variables locales.
%	Las variables no tienen que ser de las mismas dimensiones
%	 pero sí del mismo tamaño, tipo y complejidad
%
%	El tamaño y tipo de datos a enviar se deduce de la variable
%	Si es compleja, la parte compleja se reduce después de la real
%
%  Implementación MEX completa: src/pvm_reduce.c, pvm/MEX/pvm_reduce.mexlx

