%PVM_CATCHOUT		Captura stdout tareas hijas en fichero (default stdout)
%
%  info = pvm_catchout [ (fildes) ]	* fildes en vez de stream
%
%  info  (int) 0 siempre
%  fildes(int) file identifier/descriptor al estilo de
%	Matlab:	fildes=fopen(filename,permission)
%	C:	int     open(const char *pathname, int flags, mode_t mode)
%       0 para desconectar captura  
%	1 para stdout (valor por defecto)
%       2 para sterr  (ver fprintf)
%
%			Se usa FILE *fdopen(int fildes, const char *mode)
%	  para crear un stream (para PVM) a partir de fildes (Matlab/shell)
%
%  Implementación MEX completa: src/pvm_catchout.c, pvm/MEX/pvm_catchout.mexlx

