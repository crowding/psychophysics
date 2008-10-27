function makepsig(varargin)

% MAKEPSIG    compiles the psignifit engine as a MEX file
% 
% The mex script will create a project file, and attempt to compile it.
% On some systems (combinations of OS and C compiler) the factory settings
% will cause compilation to fail. You may need to open up the project file
% that has been created, change a few options, and make the MEX file
% manually. Here are a few notes, based on the systems we have tried so far.
% Any additions to these tips, based on your own experience, would be
% appreciated: psignifit@bootstrap-software.org
% 
% Windows or Mac
% * to set the correct options for your compiler you may need to invoke
%   "mex -setup" first before running this script
% 
% Windows
% * The only success I have had is with Cygwin gcc, the free win32 port of
%   the gnu compiler gcc. Presumably MinGW will work as well. Instructions
%   can be found at:
%       http://www.mrc-cbu.cam.ac.uk/Imaging/gnumex20.html
%   For portability, mingw or cygwin-mingw linking is recommended.
% 
% Mac PowerPC (MacOS 9.x and below) with CodeWarrior
% * default instruction scheduling is set for 601 processors for some reason.
%   Change the setting (in the "PPC processor" project settings panel) if you're
%   concerned about this.
% 
% * CodeWarrior Pro 2 (and up):
%   MATLAB 5 fails to look after the following bits of housekeeping that are
%   necessary in CodeWarrior Pro 2:
% 
%   - check "map newlines to CR" in "C/C++ Language" project settings panel,
%     otherwise any text output from the mex file will look very strange
%   - remove cpp init file from project segment "MATLAB"
%   - remove the dummy file <replace me.c> if it hasn't been remove automatically
%   - on PowerPC: remove cpp entry point from "Initialization" in "PPC Linker"
%     project settings panel

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/


targetName = 'psignifit';
sourceDirName = 'psig-src';

if postr13 % support for -V4 is claimed to exist but is broken in R13
    compat = {'-V5'};
else % define V4_COMPAT *and* V5_COMPAT, so that the source code knows what's going on 
    compat = {'-V4', '-DV5_COMPAT'};
end
if postr14
	st = dbstack('-completenames');
	toolboxDirPath = fileparts(st(1).file);
else
	st = dbstack;
	toolboxDirPath = fileparts(st(1).name);
end
disp(sprintf('PSIGNIFIT toolbox directory is %s', toolboxDirPath))
sourceDirPath = fullfile(toolboxDirPath, sourceDirName);
if ~exist(sourceDirPath, 'dir')
	error(sprintf('please put the C source files in a directory called ''%s'' inside the PSIGNIFIT toolbox directory', sourceDirName))
end
sourceFiles = dir(fullfile(sourceDirPath, '*.c'));
sourceFiles = {sourceFiles.name}';
if isempty(sourceFiles)
	error(sprintf('found no C source files in %s', sourceDirPath))
end
for i = 1:length(sourceFiles), sourceFiles{i} = fullfile(sourceDirPath, sourceFiles{i}); end
targetFile = fullfile(toolboxDirPath, targetName);
lasterr('')
eval('mex(compat{:}, ''-output'', targetFile, varargin{:}, sourceFiles{:})', '')
error(lasterr)
