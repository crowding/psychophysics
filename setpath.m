function setpath()
%sets the path appropriate for eye tracking code to function.

%the directory we sit in
p = fileparts(mfilename('fullpath'));

% get all the library paths and the root code path
% subdirectories ought to be managed by a pakage/namespace system, if
% matlab 

%all the library paths (dependent on OS version)
if strcmp(computer, 'MAC')
    path = genpath(fullfile(p, 'library', 'osx'));
elseif strcmp(computer, 'MAC2')
    path = genpath(fullfile(p, 'library', 'os9')); 
    %actually, this script won't even run in matlab 5...
else
    error('eyetracking:unsupported_arch');
end

path = regexp(path, ['[^' pathsep ']+'], 'match'); %split on pathseps

%filter out those .svn paths
nosvn = ~cellfun( @length, regexp(path, '(\.svn|\.bundle|/private|.FBC)', 'match') ); %logical array
path = path(nosvn);

%join paths with path separator characters
%path = cellfun(@(x) [x pathsep], path, 'UniformOutput', 0);
%path = cat(2, path{:});

%finally use the code and data paths. These paths are not added recursively
%because I would prefer to use some namespace mechanism to avoid naming
%conflicts, like every other reasonable programming language provides.
path = {path{:}, fullfile(p, 'code'), fullfile(p, 'data')};

addpath(path{:});