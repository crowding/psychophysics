function str = join(j, strs)

save = strs(end);
strs = strcat(strs, {j}); %BLEARGH it chomps whitespace, FIXME:
strs(end) = save;
str = strcat(strs{:});