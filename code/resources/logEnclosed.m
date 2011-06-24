function initializer = LogEnclosed(varargin)
    initializer = @logInitializer;

    function [release, params] = logInitializer(params)
        str = sprintf(varargin{:});
        
        fprintf(params.logf, 'BEGIN %s\n', str');
        
        release = @logExit;
        function logExit
            fprintf(params.logf, 'END %s\n', str);
        end
    end
end