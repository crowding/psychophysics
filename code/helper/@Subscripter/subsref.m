function varargout = subsref(this, S)

args = S(1).subs;
rest = S(2:end);

[varargout{1:nargout}] = subsref(args{1}, rest);

%varargout = cell(1, numel(args));
%for i = 1:numel(args)
%    varargout{i} = subsref(args{i}, rest);
%end

%{
outs = cellfun(@(subs)subsref(subs, rest), args, 'UniformOutput', 0)
[varargout{1:numel(S(1).subs)}] = outs{:};
%}