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