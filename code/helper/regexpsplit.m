function strs = regexpsplit(str, exp)
    strs = regexp(str, ['(.+?)' '(?:' exp '|$)' ], 'tokens');
    strs = cellfun(@(x) x{1}, strs, 'UniformOutput', 0);
end