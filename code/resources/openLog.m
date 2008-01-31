function init = openLog(varargin)
%produces a log file initializer.
[tempdir, filename] = fileparts(tempname());;

defaults = struct('logfile', filename, 'log', []);

init = currynamedargs(@initLog, defaults, varargin{:});

    function [release, params] = initLog(params)
        if ~isempty(params.logfile) && isempty(params.log)
            fname = fullfile(env('datadir'), params.logfile);
            file_ = fopen(fname, 'a');
            if (file_ <= 0)
                error('openLog:problemOpeningFile', 'status %d opening log file "%s"', file_, fname);
            end
        else
            file_ = -1;
        end
        
        if isempty(params.log)
            params.log = @logMessage;
        end
        
        
        %test line breaking (FIXME: should be a unit test)
        %logMessage([repmat('1234567890', 1, 22) '12']);
        %logMessage([repmat('1234567890', 1, 22) '123']);
        %logMessage([repmat('1234567890', 1, 22) '1234']);

        release = @closeLog;

        function closeLog
            if file_ > 0
                fclose(file_);
                disp(sprintf('logged to %s', params.logfile));
            end
        end

        %now this is just unnecessary if we're not saving an EDF.
        %But the EDF is just unnecessary if we're streaming...
        %but since the Eyelink is opened after us we don't know if we're
        %streaming...
        
        function logMessage(varargin)
            %log a message with args like sprintf. If the eyelink is connected,
            %logs the message to the eyelink.
            str = sprintf(varargin{:});
                
            if file_ > 0
                fprintf(file_, '%s\n', str);
            end
            
        end
    end
end
