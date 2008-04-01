function varargout = cellreduce(fn, varargin)
    %function [argsout{1:n}] = cellreduce(fn, initialstate{1:n}, inputs{1:n+m}, ['UniformOutput', 1|0] )
    %
    %Is to REDUCE as CELLFUN is to MAP. Supports multiple input and output arguments;
    %specify all the initial states and then the input cell arrays.
    %(the number of output arguments and number of initial states must
    %be equal, though the function can take extra inputs).
    %
    %Simple example: a silly way to sum a list of numbers.
    %
    %>> rsum = @(x)cellreduce(@plus, 0, num2cell(x));
    %>> y = rsum(1:100)
    %y =
    %    5050
    %
    %Note that this depends crucially on the number of output arguments you
    %call with. Multiple output arguments are a complete hack and
    %one of the worst things about matlab. Reasonable languages have
    %destructuring-bind and operate on collections.
    %
    %Note that error handlers won't work the way they do in CELLFUN.

    no = nargout;
    accum = varargin(1:no);

    cellfun(@step, varargin{no+1:end});
        function step(varargin)
            [accum{1:no}] = fn(accum{:}, varargin{:});
        end
    
    varargout = accum;
end