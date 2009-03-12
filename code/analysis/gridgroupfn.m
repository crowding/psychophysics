function [g, out] = gridgroupfn(array, varargin)
%function [g, varargout] = gridgroup(array, varargin)
%
%groups ARRAY into a multidimensional cell array of bins according to the
%variable number of input functions given.

parameters = zeros(numel(varargin), numel(array));

for fni = 1:numel(varargin)
    if iscell(array)
        parameters(fni,:) = cellfun(varargin{fni}, array(:))';
    else
        parameters(fni,:) = arrayfun(varargin{fni}, array(:))';
    end 
end

[g, out] = gridgroup(parameters, array);

end