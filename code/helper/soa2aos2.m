function aos = soa2aos2(soa, dims)
    %With the sense of 'dims' inverted...
    fields = fieldnames(soa);
    values = struct2cell(soa);
    if nargin < 2
        values = cellfun(@num2cell, values, 'UniformOutput', 0);
    else
        values = cellfun(@(x)num2cell2(x,dims), values, 'UniformOutput', 0);
    end
    args = cat(1, fields', values');
    aos = struct(args{:});
end