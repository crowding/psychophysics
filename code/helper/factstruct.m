function fact = factstruct(factors)
    names = fieldnames(factors);
    values = struct2cell(factors);
    
    [factorialized{1:size(values)}] = ndgrid(values{:});
    factorialized = cellfun(@num2cell, factorialized, 'UniformOutput', 0);
    structargs = cat(1, names(:)', factorialized(:)');
    fact = struct(structargs{:});
end