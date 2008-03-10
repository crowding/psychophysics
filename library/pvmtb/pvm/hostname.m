function str = hostname()
%HOSTNAME		Devuelve el nombre del ordenador
%
%  'str' = hostname
%
%  Implementación M total

[retcode str]=unix('hostname');
str(end)=[];

%		Durante el cálculo se necesita crear un fichero temporal (/tmp)
% tmpfile = tempname;			% En un ficherillo
% unixcmd = ['!hostname >' tmpfile];	%  escribir el hostname local
% eval     (unixcmd);
% str     = textread(tmpfile,'%c')';	%  para poder leerlo en variable Matlab
% delete   (tmpfile);			% (ficherillo es sólo paso intermedio)

