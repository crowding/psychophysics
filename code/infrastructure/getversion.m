function v = getversion(frameno)
%getversion(frame)
%
%takes a stack frame index, where getversion is index 0, and returns
%versioning information in a structure with fields:
%
%'function' the full name of the function
%'url' the full URL in the SVN repository
%'revision' the last modified revision number
%'parents' the versions of parent objects (for inherited objects)

%grab the stack frame and the handle
[st, i] = dbstack('-completenames');
frameix = min(numel(st), i + frameno);
frame = st(frameix);

persistent cache;
persistent svnloc;
if isempty(svnloc)
    [a, s] = system('which svn');
    if exist(s, 'file');
        svnloc = a;
    elseif exist('/sw/bin/svn', 'file');
        svnloc = '/sw/bin/svn';
    elseif exist('/usr/local/bin/svn', 'file');
        svnloc = '/usr/local/bin/svn';
    else
        warning('getversion:svn', 'SVN not found!');
        v = struct('function', frame.name, 'url', '', 'revision', NaN, 'parents', {{}});
        return;
    end
end 

% use a struct as pretend associative array by cleaning the file names (hackish)

e = env;

%the key to the hash is the file name plus anything following the parent
%function name (for nested functions)
fieldname = [...
    strrep(frame.file, [e.basedir '/'], '')...
    regexprep(frame.name, '^[a-zA-z][a-zA-Z0-9_]*', '', 'once')...
    ];

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

    %actually grab the version information
    [status, info] = system(sprintf('%s info %s', svnloc, frame.file));
    if status ~= 0
        warning('getversion:svn', 'couldn''t call svn on %s', frame.file);
        v = struct('function', frame.name, 'url', '', 'revision', NaN, 'parents', {{}});
        return
    end

    url = regexp(info, '(?:^|\n)URL: (.*?)(?:$|\n)', 'tokens', 'once');
    revision = regexp(info, '(?:^|\n)Last Changed Rev: (.*?)(?:$|\n)', 'tokens', 'once');

    if isempty(url)
        warning('getversion:urlNotFound', 'could not get url from SVN response for file ''%s''', frame.file);
        url = {''};
    end

    if isempty(revision)
        warning('getversion:revisionNotFound', 'could not get revision from SVN response for file ''%s''', frame.file);
        revision = {'NaN'};
    end

    revision = str2num(revision{1});

    v = struct('function', frame.name, 'url', url{1}, 'revision', revision, 'parents', {{}});
    
    cache(1).(fieldname) = v;
end