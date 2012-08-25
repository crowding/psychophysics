function x = dependencies(mfile, outfile)

%generate a space-delimited list of the user-created dependencies of an
%M-file, and write that list to a file. This is used for makefiles.
if ~isempty(mfile)
    p = fdep(mfile, '-q');
else
    p.fun = {};
end

%we don't include itself in the dependency list.
p.fun = strrep_at_beginning(p.fun,[fullfile(pwd()), filesep], '');

x = p.fun;

x(strcmp(x, mfile)) = [];

if (nargin >= 2)
    require(openFile(outfile, 'w'), @(x)fprintf(x.fid,'%s\n',x));
end
end

function origStr = strrep_at_beginning(origStr, oldSubstr, newSubstr)
    matches = strncmp(origStr, oldSubstr, numel(oldSubstr));
    origStr(matches) = regexprep(origStr(matches), sprintf('^.{%d}', numel(oldSubstr)), '');
    origStr(matches) = strcat(newSubstr, origStr(matches));
end