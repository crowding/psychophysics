function cloned = deepclone(obj, varargin)
    props = obj.property__();
    vals = cellfun(obj.property__, props, 'UniformOutput', 0);
    vals = cellfun(@deep, vals, 'UniformOutput', 0);
    args = {props{:}; vals{:}};
    func = str2func(obj.version__.function);
    cloned = func(args{:}, varargin{:});
end


function val = deep(val)
    if isstruct(val) && isfield(val, 'property__')
        val = deepclone(val);
    end
end