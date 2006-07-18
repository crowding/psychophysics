%startup.m file
function startup()

%Place or symlink this file in the MATLAB startup directory (on OSX, this
%is /Applications/MATLAB71 )

%since matlab is dumb, it provides no provision for doing a user-specific
%atartup script, in a way similar to every unix program in existence. wtf?

%So on this machine, we will look under ~/.matlab for
%another startup.m file.

[status, home] = system('echo -n $HOME');
startupfile = fullfile(home, '.matlab', 'startup.m');

if (exist(startupfile, 'file') == 2) || (exist(startupfile, 'file') == 6) 
   % 2 = 'is it a file', 6 == 'is it a P-file'
   run(startupfile);
end
