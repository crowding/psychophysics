function str = join(j, strs)
% function str = join(j, strs)
% 
% concatenates the strings in strs, interposing j as the separator.
if numel(strs) == 0
    str = char(1,0);
    return
end

save = strs(end);
strs = append(strs, j);
strs(end) = save;
try
str = cat(2,strs{:});
catch
    noop();
end

end

function strs = append(strs, app)
try
    strs = cellfun(@(s) [s app], strs, 'UniformOutput', 0);
catch
    noop();
end
end    