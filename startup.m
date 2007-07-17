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
   addpath(cleanpath(genpath(toolbox)));
end


%and then run the per-user config script
if (exist(startupfile, 'file') == 2) || (exist(startupfile, 'file') == 6) 
   % 2 = 'is it a file', 6 == 'is it a P-file'
   olddir = pwd();
   cd(dir);
   newdir = pwd();
   startup;
   if strcmp(newdir, pwd)
       %this provides an "out" for startup scripts that want to set the
       %initial directory
       cd(olddir);
   end
end

[s, w] = system('hostname');
if strfind(w, 'pastorianus')
    addpath('/Users/peterm/work/eyetracking/trunk/switchbox/shadow', '/Users/peterm/work/eyetracking/trunk/switchbox');
end

function p = cleanpath(p)
    %clean junk/SVN directories from a path string.
    p = regexprep(p, '(^|:)[^:]*(\.svn|\.bundle|/private|.FBC|@)[^:]*', '');
end

end
