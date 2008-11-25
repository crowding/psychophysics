function s = structcat(varargin)
    %take a cell array(s) of structs, and concatenate them into a regular
    %array of structs with the union of all fields.
    
    if numel(varargin) > 1
        varargin = cellfun(@(i) i(:), varargin, 'UniformOutput', 0);
        s = varargin;
    else
        s = varargin{1};
    end
    s = structcat_cell(s);
end

function s = structcat_cell(c)
    fnames = cellfun(@fieldnames, c, 'UniformOutput', 0);
    fnames = unique(cat(1, fnames{:}));
    values = cell(numel(c), numel(fnames));
    for i = 1:numel(fnames)
        for j = 1:numel(c);
            if isfield(c{j}, fnames{i});
                values{j,i} = {c{j}.(fnames{i})}';
            else
                values{j,i} = cell(size(c{j}));
            end
        end
    end

    values = num2cell(values, 1);
    values = cellfun(@(x)cat(1, x{:}), values, 'UniformOutput', 0);
    args = {fnames{:};values{:}};
    s = struct(args{:});
end


function varargout = applyargs(fn, c)
    [varargout{1:nargout}] = fn(c{:});
end