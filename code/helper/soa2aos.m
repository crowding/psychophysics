function aos = soa2aos(soa, dims)
    %converts struct-of-arrays to array-of-structs...
    fields = fieldnames(soa);
    values = struct2cell(soa);
    if nargin < 2
        values = cellfun(@num2cell, values, 'UniformOutput', 0);
    else
        values = cellfun(@(x)num2cell(x,dims), values, 'UniformOutput', 0);
    end
    args = cat(1, fields', values');
    aos = struct(args{:});
end