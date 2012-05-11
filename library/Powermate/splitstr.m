function strs = splitstr(sep, str)
    % function strs = splitstr(sep, str)
    % splits delimiter-separated atrings into a cell array.

    indices = strfind(str, sep);
    begins = [1 indices+length(sep)];
    ends = [indices-1 length(str)];
    
    %strs = arrayfun(@(x, y) str(x:y), begins, ends, 'UniformOutput', 0); %was 0.60 / 1569
    strs = cell(numel(begins), 1); %now much faster
    for i = 1:numel(begins)
        strs{i} = str(begins(i):ends(i));
    end
end