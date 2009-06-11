function dependencies(mfile, outfile)

%generate a space-delimited list of the user-created dependencies of an
%M-file, and write that list to a file. This is used for makefiles.
if ~isempty(mfile)
    p = fdep(mfile, '-q');
else
    p.files = {};
end

require(openFile(outfile, 'w'), @(x)fprintf(x.fid,'%s\n',p.fun{:}));