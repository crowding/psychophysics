function initializer = LogEnclosed(varargin)
    initializer = @logInitializer;

    function [release, params] = logInitializer(params)
        str = sprintf(varargin{:});
        
        params.log('BEGIN %s', str);

        release = @logExit;
        function logExit
            params.log(['END %s', str]);
        end
    end

end