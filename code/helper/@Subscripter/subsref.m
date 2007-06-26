function varargout = subsref(this, S)

%we can apply subsref's in parallel...
args = S(1).subs;
rest = S(2:end);


varargout = cell(1, numel(args));
for i = 1:numel(args)
    varargout{i} = subsref(args{i}, rest);
end

%{
outs = cellfun(@(subs)subsref(subs, rest), args, 'UniformOutput', 0)
[varargout{1:numel(S(1).subs)}] = outs{:};
%}