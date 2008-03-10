%PVM_PUTINFO		Almacena mensaje en el Mailbox Global
%
%  index = pvm_putinfo('name', bufid, flags)
%
%  name  (string) nombre de entrada a añadir a Mailbox
%  bufid (int)    id.buffer de envío a asociar con entrada Mailbox
%  flags (int)    opciones, OR de los siguientes bits
%        0 PvmMboxDefault	instancia no persistente, simple, bloqueada
%        1 PvmMboxPersistent	permanece tras salida creador
%        2 PvmMboxMultiInstance	permite entradas múltiples con mismo nombre
%        4 PvmMboxOverWritable	permite que otra tarea sobreescriba
%
%  index (int) índice en Mailbox asignado por PVMd
%       <0 código de error
%      -33 PvmExists : ya existe dicha clave (name)
%       -8 PvmDenied : ya hay una entrada bloqueada con dicho nombre
%       -2 PvmBadParam (bufid)
%      -16 PvmNoSuchBuf
%      -10 PvmNoMem
%
%  Implementación MEX completa: src/pvm_putinfo.c, pvm/MEX/pvm_putinfo.mexlx

