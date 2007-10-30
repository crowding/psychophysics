function out = set(this, what, to)
wrapped = builtin('subsref', this, substruct('.', 'wrapped'));

if nargin <= 1
    if isobject(wrapped)
        fnames = wrapped.property__();
        values = cellfun(@(x){{}}, fnames, 'UniformOutput', 0);
        args = {fnames{:}; values{:}};
        out = struct(args{:});
    elseif isstruct(wrapped)
        out = structfun(@(x){}, wrapped, 'UniformOutput', 0);
    else
        out = set(wrapped);
    end
else
    error('not written');
end