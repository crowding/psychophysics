function changed = triplediff(old, a, b, evalfna, evalfnb)

%takes an "old" reference and functions a and b generates calls to
%incorporate both changes, changes from A applying before changes from B.
    changed = old;

    function change(subs, what)
        subsasgn(changed, subs, what);
        fprintf('%s%s = %s\n', substruct2str(subs), smallmat2str(what));
    end

    function filter(subs, fn)
        subsasgn(changed, subs, subsref(changed, subs));
        fprintf( '%s%s = %s(%s%s)\n', name, substruct2str(subs) ...
               , func2str(what), name, substruct2str(subs));
    end

    name = 'a';
    diffvisit(old, a, @change, @filter);
    name = 'b';
    diffvisit(old, b, @change, @filter);
end