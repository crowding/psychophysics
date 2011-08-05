function accum = pipe(in, varargin)

    accum = in;
    cellfun(@f, varargin)
    function f(in)
        accum = in(accum);
    end
end