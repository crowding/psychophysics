function info = pvme_start_pvmd(varargin)
%PVME_START_PVMD	Arranque daemon PVMD con comodidades, man pvmd(1PVM)
%
%  info = pvme_start_pvmd [ ( ['arg' [,'arg']...]  [,'hostfile']  [,block] ) ]
%
%    block  0 retorna inmediatamente
%         !=0 retorna tras añadir los hosts (valor por defecto)
%             Último argumento, opcional
%
%    hostfile  fichero de hosts PVM, debe existir en Matlab path
%              incompatible con conflines, si existe se ignoran conflines
%              penúltimo o último argumento, opcional
%              si tampoco hay conflines, es como si se hubiera puesto 'd'
%
%    arg  (-option | confline) opción pvmd o línea hostfile
%          -option: -dmask -nname -s -S -f
%           confline: hostname [*] lo=logname so=passwd dx=file ep=path
%                               wd=workdir sp=speed bx=debugger ip=hostname
%
%	   'd' para usar configuración por defecto (ver pvm_default_config)
%              Incompatible con cualesquiera otras conflines (se ignorarán)
%              Si no hay conflines ni hostfile, es como si se hubiera puesto 'd'
%              Primer argumento
%
%    info  0 PvmOk
%        -28 PvmDupHost
%        -14 PvmSysErr
%
%  Implementación M parcial: pvm_start_pvmd.c, pvm_start_pvmd.mexlx

info = 0;					% Debería ser PvmOk
if nargin>0
  block=varargin{end};
  if isnumeric(block), varargin(end)=[];
  else,        block=1;         end
else,          block=1;         end

if ~iscellstr(varargin)
  info = -2;					% Debería ser PvmBadParam
  error('argumentos deben ser strings, salvo block')
else
  if isempty(varargin), hostfile=['/tmp/pvmdefconf.' uid];	% Como si 'd'
  else
    hostfile=varargin{end};
    if hostfile(1)=='-', hostfile=[];	% No hay hostfile, es última -option
    else				% No es -option
      hostfile=which(hostfile);		%  intentar sacarlo del Matlab path
      if ~isempty(hostfile)		%  existe, interpretar como hostfile
        varargin(end)=[];		% Dejar args sólo
      end
    end
  end
  lasto=0; opts={};
  lastc=0; cnfg={};
  for i=1:length(varargin)		% Si no hay args, for no hace nada
    elmnt=varargin{i};
    if elmnt(1)=='-', lasto=lasto+1; opts(lasto)={elmnt};
    else            , lastc=lastc+1; cnfg(lastc)={elmnt};
    end
  end
  if lastc~=0 ...			% Existen líneas de configuración
   &~isempty(hostfile)			% y fichero de configuración
    warn=[hostfile ' existe, y hay líneas conf' ...
    char(10) '         Se ignorarán las líneas de configuración'];
              warning(warn);
    info = -3;				% Debería ser PvmMismatch
    lastc=0; cnfg={};			% Ignorar líneas conf
  end
  if lastc~=0		% Hay líneas de configuración (fichero ya no)
    if cnfg{1}=='d'		% Se trata de configuración por defecto
      hostfile=['/tmp/pvmdefconf.' uid];	% Incluso si no existe,
      if lastc>1			% Y existen más líneas de configuración
        warn=['se indicó configuración por defecto, y hay líneas conf' ...
        char(10) '         Se ignorarán las líneas de configuración'];
                  warning(warn);
        info = -3;			% Debería ser PvmMismatch
      end
    else					% se ignorarán conflines
      hostfile=tempname; lastc=-1;	% Si no, pasarlas mediante fichero
      fid=fopen(hostfile,'w');		% lastc==-1 recuerda que es temporal
      for i=1:length(cnfg), fprintf(fid, '%s\n', cnfg{i}); end
      fclose(fid);
    end
  end			% fichero se pasa como último arg a pvm_start_pvmd()
  if ~isempty(hostfile), lasto=lasto+1; opts(lasto)={hostfile}; end

  info = pvm_start_pvmd(opts,block);

  if lastc<0, delete(hostfile); end	% Si lo creamos, lo borramos
end

