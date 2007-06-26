function str = struct2str(s)

x = cat(2, fieldnames(s), struct2cell(s))';
str = sprintf('%s %f ', x{:});