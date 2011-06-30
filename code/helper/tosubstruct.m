function subs = tosubstruct(subs)
its_ = Genitive();
if ischar(subs)
    %convert to a substruct...
    try
        subs = eval(sprintf('(its_.%s);', subs));
    catch
        errorcause(lasterror, 'Randomizer:invalidSubscript', 'Invalid subscript reference ".%s"', subs);
    end
end

%check that you actually have a substruct
try
    subs = subsref(its_, subs);
catch
    errorcause(lasterror, 'Randomizer:invalidSubscript', 'Improper substruct');
end
end