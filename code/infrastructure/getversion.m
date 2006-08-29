function v = getversion(frame)
%getversion(frame)
%
%takes a stack frame index, where getversion is index 0, and returns
%versioning information in a structure with fields:
%
%'function' the full name of the function
%'url' the full URL in the SVN repository
%'revision' the last modified revision number

[st, i] = dbstack('-completenames');
frame = st(i + frame);

persistent cache;


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
%isn't entirely correct...
fieldname = regexprep(fieldname, '(^[^a-zA-Z])|([^a-zA-Z0-9])', '_');
fieldname = regexprep(fieldname, '^[^a-zA-Z]', 'f');
fieldname = fieldname(max(1,end-62):end);

if isfield(cache, fieldname)
    v = cache.(fieldname);
else

    [status, info] = system(sprintf('/usr/local/bin/svn info %s', frame.file));
    if status ~= 0
        warning('getversion:svn', 'couldn''t call svn in %s', frame.file);
        v = struct('function', frame.name, 'url', '', 'revision', NaN);
        return
    end

    url = regexp(info, '(?:^|\n)URL: (.*?)(?:$|\n)', 'tokens', 'once');
    revision = regexp(info, '(?:^|\n)Last Changed Rev: (.*?)(?:$|\n)', 'tokens', 'once');

    if isempty(url)
        warning('getversion:urlNotFound', 'could not get url from SVN response');
        url = {''};
    end

    if isempty(revision)
        warning('getversion:revisionNotFound', 'could not get revision from SVN response');
        revision = {'NaN'};
    end

    revision = str2num(revision{1});

    v = struct('function', frame.name, 'url', url{1}, 'revision', revision);
    
    cache(1).(fieldname) = v;
end