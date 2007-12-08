function v = enumToNumber(v, enum)
    if isstruct(v) && isfield(v, 'enum_')
        v = double(v.enum_);
        x = fieldnames(enum);
        v = enum.(x{3});
    elseif ischar(v) || iscell(v)
        if all(isfield(enum, v))
            if iscell(v)
                m = zeros(size(v));
                for i = 1:numel(m)
                    m(i) = enum.(v{i});
                end
                v = m;
            else
                v = enum.(v);
            end
        elseif isempty(v)
            v = [];
        else
            error('enum:unknownValue', 'Unknown value(s) %s (options are %s)'...
                 , join(', ', setdiff(v, fieldnames(enum))) ...
                 , join(', ', setdiff(fieldnames(enum), {'enum_', 'lookup_'}))...
                 );
        end
    elseif isnumeric(v) 
        if any(numel(enum.lookup_) <= v) || any(~numel(enum.lookup_{v+1}))
            error('Unknown enum value %d (options are %s)', v, sprintf('%d,', find(cellfun('prodofsize', enum.lookup_)) - 1));
        end
        %else is left alone
    end
end