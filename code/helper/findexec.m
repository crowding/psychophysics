function bin = findexec(command)
%Find the full path to some program.

persistent path;
if isempty(path)
    %find the user's shell path (sometimes not the same path Matlab runs with)
    [~, path] = system('$SHELL -c "printf %s \"$PATH\""');
end

%If I can't determine where an execuatble is, try finding the user's
%real $PATH and run again.

%god, escaping for the shell is so annoying.
oldpath = getenv('PATH');
x = onCleanup(@(x)setenv('PATH', oldpath));
setenv('PATH', path);
command = sprintf('printf %%s `which %s`', shellquote(command));
[~, bin] = system(command);

end
