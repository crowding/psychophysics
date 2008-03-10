function info = pvme_default_config(varargin)
%PVME_DEFAULT_CONFIG	Copia (fichero) configuración PVM a /tmp/pvmdefconf.uid
%
%  info = pvme_default_config [ ('hostfile') ]
%  info = pvme_default_config( 'confline' [, 'confline']... )
%    hostfile Nombre de fichero hosts PVM en Matlab path (opcional)
%             Si no se indica, se busca un fichero 'pvmdefconf.m'
%             Si tampoco existe, saldrá una configuración vacía
%    confline Líneas deseadas del fichero, cada línea en un string
%             Si la primera coincide con un hostfile, las demás se ignoran
%
%  Implementación M total

info = 0;				% Debería poner PvmOk

if nargin==0
  hostfile=which('pvmdefconf');		% Si no se indica, 'pvmdefconf.m'
else
  if ~iscellstr(varargin)
    info = -2;				% Debería ser PvmBadParam
    error('argumentos deben ser strings')
  else
    hostfile=which(varargin{1});
    if ~exist(hostfile,'file')		% Si existe, se interpreta como hostfile
      hostfile=[]; end			% Si no existe, debe ser confline
  end
end

destfile=['/tmp/pvmdefconf.' uid];	% Generar conffilename

if isempty(hostfile)			% No existe
  fid=fopen(destfile,'w');		%  crear destino con conflines
  for i=1:length(varargin)		%  posiblemente ninguna
    fprintf(fid, '%s\n', varargin{i});	%  cada una en una línea aparte
  end
  fclose(fid);
else
  copyfile(hostfile,destfile)		% Sí existe, copiar
end

