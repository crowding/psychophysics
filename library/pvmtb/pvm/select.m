%SELECT			Ejercita syscall select(), algo así como KeyPressed
%
%  info = select [ (fildes [, timeout] ) ]
%
%  fildes (int arr) array de descriptores a observar en lectura
%		0 suele ser STDIN (default)
%		obtener otros descriptores con pvm_getfds()
%
%  timeout (double) tiempo máximo a esperar
%			si 0 ó no indicado, retornar inmediatamente (default)
%  info 0 no hay nada
%      >0 #descriptores en los que se ha recibido algo para lectura
%      -1 error
%
%  Implementación MEX completa: src/select.c, pvm/MEX/select.mexlx
%

