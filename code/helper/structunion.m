function out = structunion(varargin)
    %builds a structure that is the union of the argument structures.
    names = cellfun(@fieldnames, varargin, 'UniformOutput', false);
    names = cat(1, names{:});
    values = cellfun(@struct2cell, varargin, 'UniformOutput', false);
    values = cat(1, values);
    
    [names, indices] = unique(names, 'last');
    values = values(indices);
    values = num2cell(values); %needed because STRUCT does what you don't want if some fields are cells and some aren't
    
    args = cat(1, names(:)', values(:)');
    out = struct(args{:});
end