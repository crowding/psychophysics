function varargout = apply(fn, args)
%apply a function to a cell array of arguments.
[varargout{1:nargout}] = fn(args{:});
