function val = enumToString(val, enum)
    if isstruct(val) && isfield(val, 'enum_');
        val = struct2cell(val);
        val = shiftdim(val{3,:}, 1);
    elseif ischar(val) || iscell(val)
        if ~all(isfield(enum, val))
            %cell array of string supported
            error('enum:unknownValue', 'Unknown value(s) %s (options are %s)'...
                 , join(', ', setdiff(val, fieldnames(enum))) ...
                 , join(', ', setdiff(fieldnames(enum), {'enum_', 'lookup_'}))...
                 );
        end
    elseif isnumeric(val)
        if isscalar(val)
            if numel(enum.lookup_) <= val || isempty(enum.lookup_{val+1});
                error('enum:unknownValue', 'Unknown enum value %d (options are %s)', val, sprintf('%d,', find(numel(enum.lookup_{:})) - 1));
            else
                val = enum.lookup_{val+1};
            end
        else
            if any(numel(enum.lookup_) <= val) || any(~cellfun('prodofsize', enum.lookup_(val+1)))
                error('enum:unknownValue', 'Unknown enum value(s) %s (options are %s)', sprintf('%d,', setdiff(val, find(cellfun('prodofsize', enum.lookup_)) - 1)), sprintf('%d,', find(cellfun('prodofsize', enum.lookup_)) - 1));
            else
                val = enum.lookup_(val+1);
            end
        end
    end
end