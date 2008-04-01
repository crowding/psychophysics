function i = ind2subscript(array, index, varargin)

[i{1:ndims(array)}] = ind2sub(size(array), index);
i = [i{:}];

if ~isempty(varargin)
    i = i(varargin{:});
end