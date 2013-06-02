function v = getversion(frameno)
%getversion(frame)
%
% Called with no arguments, gets version information of the calling
% function.
%
% Called from within some function, will try to obtain revision
% control information for that function.
%
% Can also be called with a function handle, in which case it will get
% you the version info of that function.
%
% For any functions you would like to record the versions of, I
% recommend that you keep the results in a persistent variable and use
% the pattern
%
% persistent version;
% if isempty(version)
%    version = getversion()
% end
%
% as that will cache the results so that getversion runs only when a
% function's code changes.
%
% Takes a stack frame index, where getversion is index 0, and returns
% versioning information in a structure
%
% For functions stored in SVN respoitories,
%
%'function' the full name of the function
%'url' the full URL in the SVN repository
%'revision' the last revision number
%'parents' the versions of parent objects (for inherited objects)
%'modified' whether the function differs from that in the repository.
%
%Or for files stored in Git repositories:
%'function' the full name of the function.
%'gitrepo' The path to the git respostory.
%'gitpath' The path of the function's file within the repository.
%'commit' The identifier of the HEAD of the repository containing this function.

%TODO track local modifications.

if isempty(frameno)
    frameno = 1;
end

%grab the stack frame and the handle
if isnumeric(frameno)
    [st, i] = dbstack('-completenames');
    frameix = min(numel(st), i + frameno);
    frame = st(frameix);
elseif isa(frameno, 'function_handle')
    fn = functions(frameno);
    frame.name = fn.function;
    frame.file = fn.file;
end

persistent cache;
persistent svnexec;
persistent gitexec;
if isempty(svnexec)
    svnexec = findexec('svn');
end
if isempty(gitexec)
    gitexec = findexec('git');
end

% getversion info is not cached, since autoobject does caching for you

% use a struct as pretend associative array by cleaning the file names (hackish)

e = env;

%the key to the hash is the file name plus anything following the parent
%function name (for nested functions)
fieldname = [ strrep(frame.file, [e.basedir '/'], '') ...
              regexprep(frame.name, ['^[a-zA-z][a-zA-Z0-9_]*'], '', 'once') ];

%matlab provides structs, which are almost but not entirely unlike dicts,
%in that keys must be valid identifier names for some reason. So this usage
%isn't entirely correct. Come to think of it, I have to idea whether
%structs provide near-o(1) access like hashes do. I certainly wouldn't put
%it past the mathworks to be using some wholly inappropriate
%implementation.
fieldname = regexprep(fieldname, '(^[^a-zA-Z])|([^a-zA-Z0-9])', '_');
fieldname = regexprep(fieldname, '^[^a-zA-Z]', 'f');
fieldname = fieldname(max(1,end-62):end);
fieldname = regexprep(fieldname, '^_*', '');

if isfield(cache, fieldname)
    v = cache.(fieldname);
else

end


[vcsinfo, vcsdir, vcspath] = findvcs(frame.file);
v = vcsinfo(frame.file, vcsdir, vcspath);
cache(1).(fieldname) = v;

function [vcsfun, dir, relative] = findvcs(file)
    %which VCS are we running? Let's scan up for the hidden directories.
    [dir, relative, ext] = fileparts(file);
    relative = [relative ext];

    while(1)
        if exist(fullfile(dir, '.git'), 'dir')
            vcsfun = @gitinfo;
            if (isempty(gitexec))
                warning('getversion:gitNotFound', ...
                        ['Could not find the git executable. '...
                         'Make sure it is on your PATH.']);
                vcsfun = @nullinfo;
            end
            return
        end
        if exist(fullfile(dir, '.svn'), 'dir')
            vcsfun = @svninfo;
            if (isempty(svnexec))
                warning('getversion:svnNotFound', ...
                        ['Could not find the svn executable. '...
                         'Make sure it is on your PATH.']);
                vcsfun = @nullinfo;
            end
            return
        end
        [parent, next] = fileparts(dir);
        if strcmp(parent, dir)
            break;
        end
        relative = fullfile(next, relative);
        dir = parent;
    end

    vcsfun = @nullinfo;
    [dir, relative] = fileparts(file);
end

function [v, d] = nullinfo(file, dir, relative)
    warning('getversion:noRepositoryFound', ...
            ['The file "%s" does not appear to be in version control, '...
             'or the version control program was not found.'], file);
    v = struct('function', frame.name, 'file', file);
    d = '';
end

function info = gitinfo(file, dir, relative)
    [status, gitstatus] = ...
        shellcommand(gitexec, ['--git-dir=', fullfile(dir, '.git')], ...
                     'status', '-u', '-z', '--porcelain', '--', relative);
    [status, repo_rev] = ...
        shellcommand(gitexec, ['--git-dir=', fullfile(dir, '.git')], ...
                     'rev-list', '--max-count=1', '--header', ...
                     '--pretty=format:', 'HEAD');
    [status, file_last_rev] = ...
        shellcommand(gitexec, ['--git-dir=', fullfile(dir, '.git')], ...
                     'rev-list', '--max-count=1', '--pretty=format:', ...
                     'HEAD', '--', relative);

    gitstatus = gitstatus(1:min(2, numel(gitstatus)));
    repo_rev = repo_rev(min(8, numel(repo_rev)):max(end-1,0));
    file_last_rev = file_last_rev(max(min(8, numel(file_last_rev)), 1):max(end-1,0));

    info = struct('function', frame.name, 'git_repo', dir, 'path', relative, ...
                  'head_rev', repo_rev, 'last_modified_rev', file_last_rev, ...
                  'status', gitstatus, 'parents', {{}});
end

function v = svninfo(file, dir)
    %grab the version information from SVN

    [s, status] = shellcommand(svnexec, 'info', '--', file, frame.file);

    if status ~= 0
        warning('getversion:svn', 'couldn''t call svn on %s', frame.file);
        v = struct('function', frame.name, 'url', '', ...
                   'revision', NaN, 'parents', {{}});
        return
    end

    url = regexp(info, '(?:^|\n)URL: (.*?)(?:$|\n)', 'tokens', 'once');
    revision = regexp(info, '(?:^|\n)Last Changed Rev: (.*?)(?:$|\n)', ...
                      'tokens', 'once');

    if isempty(url)
        warning('getversion:urlNotFound', ...
                ['could not get url from SVN for file ''%s''. '...
                 'Have you added it to the repository?'], frame.file);
        url = {''};
    end

    if isempty(revision)
        warning('getversion:revisionNotFound', ...
                'could not get revision from SVN for file ''%s''', ...
                frame.file);
        revision = {'NaN'};
    end

    revision = str2num(revision{1});

    v = struct('function', frame.name, 'url', url{1}, ...
               'revision', revision, 'parents', {{}});

    end

end
