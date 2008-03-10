%STARTUPtbPVM		Script para añadir a startup.m, ajusta PATH y entorno
%

% Copyright (C) 1999 Javier Fernández Baldomero <jfernand@ugr.es>
% Depto. de Arquitectura y Tecnología de Computadores
% Facultad de Ciencias, Universidad de Granada
% 18071-GRANADA SPAIN

% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%

% Please read the gpl.txt file

p = getenv('PVMTB_ROOT');
if isempty(p)
  p=[getenv('HOME') '/matlab/pvmtb'];
end
q = [p '/pvm'];
if ~exist(q, 'dir'), clear p q, error('PVM Toolbox not found (M files)'), end
addpath(q);
q = [p '/pvm/MEX'];
if ~exist(q, 'dir'), clear p q, error('PVM Toolbox not found (MEX files)'), end
addpath(q);			% primero los MEX del mismo nombre
q = [p '/mm'];
if ~exist(q, 'dir'), clear p q, error('MM Toolbox not found (M files)'), end
addpath(q);
clear p q

dpy=getenv('DISPLAY');
if ~isempty(dpy), if dpy(1)==':'
  disp(['DISPLAY=' dpy])
 [dum hname]=unix('hostname');
  hname(end)=[];
  dpy=['DISPLAY=' hname dpy];
  putenv(dpy)
  disp([dpy ' *** DISPLAY changed: OK'])
  clear dum hname
end, end
clear dpy

if ~isempty(getenv('PVMEPID')),	startup_mm;	% Tareas MM/PVM hijas
else		% Instancia madre debe conocer configuración PVM
  if exist('pvmdefconf','file')
    pvme_default_config('pvmdefconf');
    disp('PVM default hostfile:')
    which 'pvmdefconf'
  else
    disp('No PVM default hostfile (pvmdefconf.m)')
  end
end  

disp('Help on PVM: help pvm, help mm')
