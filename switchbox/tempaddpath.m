function init = tempaddpath(varargin)
    defaults = namedargs('addpath', '', varargin{:});

    init = @i;

    function [r, params] = i(params)
        params = namedargs(defaults, params);

        oldpath = path();

        if iscell(params.addpath)
            addpath(params.addpath{:});
        else
            addpath(params.addpath);
        end

        r = @release;

        function release
            path(oldpath);
        end
    end
end