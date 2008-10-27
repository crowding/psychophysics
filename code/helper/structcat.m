function s = structcat(varargin)
    %take a cell array(s) of structs, and concatenate them into a regular
    %array of structs with the union of all fields.
    
    if numel(varargin) > 1
        varargin = cellfun(@(i) i(:), varargin, 'UniformOutput', 0);
        s = cat(1, varargin{:});
    else
        s = varargin{1};
    end
    s = structcat_cell(s);
end

function s = structcat_cell(c)
    %allocate the array
    if ~isempty(c)
        [sz{1:ndims(c)}] = size(c);
        s(sz{:}) = struct();
    else
        s = reshape(struct([]), size(c));
    end
    
    %walk through
    for i = 1:numel(c)
        for n = fieldnames(c{i})'
            s(i).(n{:}) = c{i}.(n{:});
        end
    end
end