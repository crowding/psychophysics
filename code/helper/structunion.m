function out = structunion(varargin)
    %builds a structure that is the union of the input structures.
    names = cellfun(@fieldnames, varargin, 'UniformOutput', false);
    values = cellfun(@struct2cell, varargin, 'UniformOutput', false);
    values = cellfun(@splitRows, values, 'UniformOutput', false);
    
    names = cat(1, names{:});
    values = cat(1, values{:});
    
    [names, indices] = unique(names, 'last');
    values = values(indices);
    values = cellfun(@(v)shiftdim(v,1),values,'UniformOutput', 0);
    
    args = cat(1, names(:)', values(:)');
    out = struct(args{:});
end

function out = splitRows(v)
    out = mat2cell(v, ones(size(v, 1),1));
end