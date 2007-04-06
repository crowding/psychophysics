function init = tempcd(varargin)
    defaults = namedargs('dir', '', varargin{:});

    init = @i;

    function [r, params] = i(params)
        params = namedargs(defaults, params);

        old = pwd();

        cd(params.dir)
        r = @release;

        function release
            cd(old);
        end
    end
end