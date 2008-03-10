%PVM_SPAWN		Arranca nuevos procesos bajo PVM
%
%  [numt tids] = pvm_spawn('task', { ['arg' [,'arg']...] } , flag,'where',ntask)
%
%  numt (int) número de tareas realmente arrancadas
%       <0    código error (ver tids)
%     ==ntask éxito total
%
%  tids (int array[ntask]) tids de las tareas PVM arrancadas
%        si hubo error parcial, algunos tids pueden ser códigos error
%	 -2 PvmBadParam
%	 -6 PvmNoHost
%	 -7 PvmNoFile
%	-10 PvmNoMem
%	-14 PvmSysErr
%	-27 PvmOutOfRes
%
%  task (string) nombre del programa, path absoluto, relativo...
%          PVM debe poder encontrarlo ($HOME/pvm3/bin/$PVM_ARCH por defecto)
%  args (cell array strings) argumentos al ejecutable, {} si no tiene
%
%  flag (int) OR lógico de las siguientes opciones
%	  PvmTaskDefault 0	PVM escoge dónde
%	  PvmTaskHost    1	'where' es hostname
%	  PvmTaskArch    2	'where' es archname
%	  PvmTaskDebug   4	arrancar bajo debugger (ver DEBUGGER en  ...)
%	  PvmTaskTrace   8	los procesos generarán traza
%	  PvmMppFront
%	  PvmHostCompl  32	Usar todos menos los host indicados
%
%  where (string) nombre de host o arch. Si flag==0, se ignora
%  ntask (int)    número de tareas a arrancar
%
%  Implementación MEX completa: src/pvm_spawn.c, pvm/MEX/pvm_spawn.mexlx

