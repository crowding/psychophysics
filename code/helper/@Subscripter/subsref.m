function varargout = subsref(this, S)

args = S(1).subs{1};
rest = S(2:end);

[varargout{1:nargout}] = subsref(args, rest);
