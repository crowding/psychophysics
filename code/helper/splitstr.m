function strs = splitstr(sep, str)
    indices = strfind(str, sep);
    begins = [1 indices+length(sep)];
    ends = [indices-1 length(str)];
    strs = arrayfun(@(x, y) str(x:y), begins, ends, 'UniformOutput', 0);
end