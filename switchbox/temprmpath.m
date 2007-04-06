function init = temprmpath(varargin)
    defaults = namedargs('rmpath', '', varargin{:});

    init = @i;

    function [r, params] = i(params)
        params = namedargs(defaults, params);

        oldpath = path();

        if iscell(params.rmpath)
            rmpath(params.rmpath{:});
        else
            rmpath(params.rmpath);
        end

        r = @release;

        function release
            path(oldpath);
        end
    end
end