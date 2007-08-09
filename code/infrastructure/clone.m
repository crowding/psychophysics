function cloned = clone(obj, varargin)
    %make a shallow copy of an object.
    %does a shallow clone of an object (all properties without
    %recursing.) Optionally specify other properties to set.
    props = obj.property__();
    vals = cellfun(obj.property__, props, 'UniformOutput', 0);
    args = {props{:}; vals{:}};
    func = str2func(obj.version__.function);
    cloned = func(args{:}, varargin{:});
end