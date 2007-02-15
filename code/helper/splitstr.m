function strs = splitstr(sep, str)
    % function strs = splitstr(sep, str)
    % splits delimiter-separated atrings into a cell array.

    indices = strfind(str, sep);
    begins = [1 indices+length(sep)];
    ends = [indices-1 length(str)];
    strs = arrayfun(@(x, y) str(x:y), begins, ends, 'UniformOutput', 0);
end