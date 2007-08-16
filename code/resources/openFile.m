function initializer = openFile(varargin)
    initializer = @init;
    
    function [release, params] = init(params)
        [params.fid, message] = fopen(varargin{:});
        
        if params.fid <= 0
            error('openFile:error', message);
        end
        
        release = @close;
        function close()
            fclose(params.fid);
        end
    end
end