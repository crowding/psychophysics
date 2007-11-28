function [C, varargout] = nunion(varargin)
%[C, IA, IB, IC, ...] = nunion(A, B, C, ...) produces the set union of its
%arguments (which may be numbers or strings.) It can take vactors or cell
%arrays of strings. C is the union set, and IA, etc. are the indices taken
%from each input argument. When two inputs contain the same element, the
%indices reflect that one from the later input is used. 
%
%This is an n-argument version of UNION.
%
%Compare this function's length to that of matlab builtin, 2-argument UNION
%(1/4 the size).

[whicharg, whichindex] = ...
    arrayfun(...
        @(i, n) deal(...
            zeros(n,1)+i,...
            (1:n)'),...
        (1:numel(varargin))',...
        cellfun('prodofsize', varargin(:)), ...
        'UniformOutput', 0 );
vector = cellfun(@(x) x(:), varargin, 'UniformOutput', 0);
vector = cat(1, vector{:});
whicharg = cat(1, whicharg{:});
whichindex = cat(1, whichindex{:});

if (nargout < 2)
    C = unique(vector);
else
    [C, i] = unique(vector);
    varargout = cell(1, nargin);
    arg = whicharg(i);
    index = whichindex(i);
    for i = 1:nargin
        varargout{i} = index(find(arg == i));
    end
end