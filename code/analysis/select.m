function varargout = select(fn, varargin)
    vin = cellfun(@cellify,varargin, 'UniformOutput', 0);
    bool = boolean(cellfun(fn, vin{:}));
    varargout = cellfun(@(x)x(bool), varargin, 'UniformOutput', 0);
end

function x = cellify(x)
    if ~iscell(x)
        x = num2cell(x);
    end
end
