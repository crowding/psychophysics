function e = enum(format, varargin)
%function e = enum(format, varargin)
%creates an enum specification. Varargin arguments are as in struct.

lookup = {};
[lookup{[varargin{2:2:end}]+1}] = varargin{1:2:end};
%support multiple values assigned to a single name, eh
args = reshape(varargin, 2, []);
[x, i] = unique(args(1,:), 'first'); i = sort(i);
e = struct('enum_', format, 'lookup_', {lookup}, args{:,i});