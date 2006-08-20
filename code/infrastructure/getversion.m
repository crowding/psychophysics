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
    error('getversion:svn', 'couldn''t call svn');
end

url = regexp(info, '(?:^|\n)URL: (.*?)(?:$|\n)', 'tokens', 'once');
revision = regexp(info, '(?:^|\n)Last Changed Rev: (.*?)(?:$|\n)', 'tokens', 'once');

if isempty(url) || isempty(revision)
    error('getversion:infoNotFound', 'could not get url and revision from SVN response');
end

revision = str2num(revision{1});

v = struct('function', frame.name, 'url', url{1}, 'revision', revision);