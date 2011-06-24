function varargout = indexgrid(in)

args = arrayfun(@(i)1:size(in,i), 1:nargout, 'UniformOutput', 0);
[varargout{1:nargout}] = ndgrid(args{:});