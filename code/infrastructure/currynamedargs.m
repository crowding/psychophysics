function fout = currynamedargs(fin, varargin)
%fout = currynamedargs(fin, varargin)
%
%combine named arguments (either as scalar structs or as named arguments)
%into one struct which is curried against the function.
args = varargin;
checknamedargs(varargin{:});

%the curried function
fout = @(varargin)fin(namedargs(args{:}, varargin{:}));