%startup.m file
function startup()

%Place or symlink this file in the MATLAB startup directory (on OSX, this
%is /Applications/MATLAB71 )

%We will look under ~/.matlab for another startup.m file.

[status, home] = system('echo -n $HOME');

toolbox = fullfile(home, '.matlab', 'toolbox');
startupfile = fullfile(home, '.matlab', 'startup.m');
dir = fullfile(home, '.matlab');

if (exist(toolbox, 'dir') == 7)
   addpath(toolbox);
end

if (exist(startupfile, 'file') == 2) || (exist(startupfile, 'file') == 6) 
   % 2 = 'is it a file', 6 == 'is it a P-file'
   olddir = pwd();
   cd(dir);
   newdir = pwd();
   startup;
   if strcmp(newdir, pwd)
       %this provides an "out" for startup scripts that want to set the initial path
       cd(olddir);
   end
end
