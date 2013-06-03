function varargout = arrayaccum(fn, varargin)
% like CELLREDUCE, but returns the accumulated values.
%function [argsout{1:n}] = cellaccum(fn, initialstate{1:n}, inputs{1:n+m}, ['UniformOutput', 1|0] )

    no = nargout;
    sz = size(varargin{1});
    accum = varargin(1:no);

    [varargout{1:nargout}] = arrayfun(@step, varargin{no+1:end});
    function varargout = step(varargin)
        [varargout{1:nargout}] = fn(accum{:}, varargin{:});
        accum = varargout;
    end
end
