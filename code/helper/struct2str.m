function str = struct2str(s)

x = cat(1, fieldnames(s)', smallmat2str(struct2cell(s))');
str = sprintf('%s=%s;', x{:});