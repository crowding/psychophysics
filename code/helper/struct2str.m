function str = struct2str(s)

x = cat(1, fieldnames(s)', struct2cell(s)');
for i = 1:size(x,2)
    x{2,i} = smallmat2str(x{2,i});
end
str = sprintf('%s=%s;', x{:});