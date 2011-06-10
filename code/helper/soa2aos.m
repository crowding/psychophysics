function aos = soa2aos(soa, dims)
    %converts struct-of-arrays to array-of-structs. This is because array
    %of structs are far easier to work with (despice struct-of arrays being
    %the "recommended" format for tabular data, there are ZERO syntactic
    %help for it. If you have trial data in a s-o-a, try extracting a
    %subset of trials, or just extracting one trial, or sorting trials, or
    %concatenating two datasets... all things that R does with "data
    %frames" with aplomb.
    
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