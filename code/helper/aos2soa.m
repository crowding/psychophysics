function soa = aos2soa(aos)
    %converts array-of-structs to struct-of-arrays...
    f = fieldnames(aos);
    c = struct2cell(aos);
    
    c = num2cell(c, 2:ndims(c));
    c = cellfun(@shiftdim, c, num2cell(ones(size(c))), 'UniformOutput', 0);
    c = cellfun(@(x) reshape([x{:}], size(x)), c, 'UniformOutput', 0);
    soa = cell2struct(c, f, 1);
end