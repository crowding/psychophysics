function s = scalarstruct(varargin)
%create a scalar struct, consistently, without the weirdness of struct()
%when called with cell array arguments.
names = varargin(1:2:end);
values = varargin(2:2:end);
values = cellfun(@(x){x}, values, 'UniformOutput', 0);
args = {names{:}; values{:}};
s = struct(args{:});
end