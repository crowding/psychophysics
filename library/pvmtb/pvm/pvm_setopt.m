%PVM_SETOPT		Ajusta el valor de alguna opción libPVM
%
%  oldval = pvm_setopt(what, val)
%
%     val (int) valor nuevo
%  oldval (int)
%        >0 valor anterior
%        -2 PvmBadParam
%
%  what  opción que se ajusta
%        PvmRoute              1    Política de Enrutamiento de Mensajes
%        val: PvmDontRoute      1    No solicitar ni conceder conexiones
%             PvmAllowDirect    2    No solicitar pero permitir (Default)
%             PvmRouteDirect    3    Solicitar y permitir conexiones
%        PvmDebugMask          2    Máscara de depuración libPVM
%        val: Nivel de depuración
%        PvmAutoErr            3    Informe automático de error
%        val: 0 No se imprimen mensajes cuando falla una llamada libPVM
%             1 Sí se imprimen en stderr (Default)
%             2 Además, se termina la tarea con exit()
%             3 Además, se aborta la tarea
%        PvmOutputTid          4    Destino de stdout de tareas hijas
%        PvmOutputCode         5    Tag para stdout hijas
%        PvmTraceTid           6    Destino de traza de tareas hijas
%        PvmTraceCode          7    Tag para traza hijas
%        PvmTraceBuffer        8    Hacer buffer de traza para hijas
%        PvmTraceOptions       9    Opciones de traza para hijas
%        val: PvmTraceFull      1    Traza completa
%             PvmTraceTime      2    Sólo timing
%             PvmTraceCount     3    Sólo profiling
%        PvmFragSize          10    Tamaño de fragmento de mensajes
%        PvmResvTids          11    Permitir Tags y Tids reservados en mensajes
%        val: 0 No se permite (Default), si se intenta se obtiene PvmBadParam
%             1 Sí se permite
%        PvmSelfOutputTid     12    Destino de stdout
%        PvmSelfOutputCode    13    Tag para stdout
%        PvmSelfTraceTid      14    Destino de traza
%        PvmSelfTraceCode     15    Tag para traza
%        PvmSelfTraceBuffer   16    Hacer buffer de traza
%        PvmSelfTraceOptions  17    Opciones de traza
%        PvmShowTids          18    pvm_catchout imprime Tids hijas
%        val: 0 No
%             1 Sí (Default)
%        PvmPollType          19    Política espera mensajes (shared memory)
%        val: PvmPollConstant   1    Consultar constantemente cola mensajes
%             PvmPollSleep      2    Consultar PvmPollTime veces, y semaphore
%        PvmPollTime          20    Duración de spinwait de mensajes
%        PvmOutputContext     21    Contexto stdout hijas
%        PvmTraceContext      22    Contexto traza hijas
%        PvmSelfOutputContext 23    Contexto stdout
%        PvmSelfTraceContext  24    Contexto traza
%        PvmNoReset           25    No matar tarea cuando reset
%        val: 0 Sí Matar (Default)
%             1 No matar
%
%  Implementación MEX completa: src/pvm_setopt.c, pvm/MEX/pvm_setopt.mexlx

