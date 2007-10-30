function x = get(this, what)

    wrapped = builtin('subsref', this, substruct('.', 'wrapped'));

    if (nargin <= 1)
        if isobject(wrapped)
            fnames = wrapped.property__();
            values = cellfun(@(x){wrapped.property__(x)}, fnames);
            args = {fnames{:}; values{:}};
            x = struct(args{:});
        elseif isstruct(wrapped)
            x = wrapped;
        else
            x = get(wrapped);
        end
    else
        error('not written');
    end
end