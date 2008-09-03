function [b, varargout] = group(parameters, varargin)


    [b, i, j] = unique(parameters, 'rows');
    
    varargout = cellfun(@index, varargin, 'UniformOutput', 0);
    
    function out = index(input)
        out = cell(size(b,1), 1);
        for ii = 1:size(b,1)
            out{ii} = input(j == ii);
        end
    end
end