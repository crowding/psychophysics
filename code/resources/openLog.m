function init = openLog(varargin)
    %produces a log file initializer
    [tempdir, filename] = fileparts(tempname());;
    
    defaults = struct('logfile', filename);
    
    init = currynamedargs(@initLog, defaults, varargin{:});
    
    function [release, params] = initLog(params)
        file_ = fopen(fullfile(env('datadir'), params.logfile), 'a');
        
        params.log = @logMessage;

        release = @closeLog;
        
        function closeLog
            fclose(file_);
            disp(sprintf('logged to %s', params.logfile));
        end
        
        function logMessage(varargin)
            %log a message with args like sprintf. If the eyelink is connected,
            %logs the message to the eyelink.
            str = sprintf(varargin{:});

            fprintf(file_, '%s\n', str);

            if Eyelink('IsConnected')
                %the eyelink toolbox is very picky and will crash eveything if
                %the string is too long or contains incorrect format
                %specifiers...
                Eyelink('Message', '%s', str(1:min(223, end)));
            end
        end
    end
end