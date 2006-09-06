function init = openLog(varargin)
%produces a log file initializer.
[tempdir, filename] = fileparts(tempname());;

defaults = struct('logfile', filename);

init = currynamedargs(@initLog, defaults, varargin{:});

    function [release, params] = initLog(params)
        file_ = fopen(fullfile(env('datadir'), params.logfile), 'a');

        params.log = @logMessage;
        
        %test line breaking (FIXME: should be a unit test)
        %logMessage([repmat('1234567890', 1, 22) '12']);
        %logMessage([repmat('1234567890', 1, 22) '123']);
        %logMessage([repmat('1234567890', 1, 22) '1234']);

        release = @closeLog;

        function closeLog
            fclose(file_);
            disp(sprintf('logged to %s', params.logfile));
        end

        function logMessage(varargin)
            %log a message with args like sprintf. If the eyelink is connected,
            %logs the message to the eyelink.
            str = sprintf(varargin{:});
            chunksize = 223;


            %the eyelink logs mesages with a maximum length of 223 chars,
            %so we should wrap longer messages (placing a backslash at the
            %end of message as reminder) into 222 char blocks.
            stop = 0;
            for i = 1:chunksize-1:numel(str)
                if numel(str) > i + chunksize-1
                    chunk = [str(i:i+chunksize-2) '\'];
                else
                    chunk = str(i:end);
                    stop = 1;
                end

                fprintf(file_, '%s\n', chunk);
                if Eyelink('IsConnected')
                    %the eyelink toolbox is very picky and will crash eveything if
                    %the string is too long or contains incorrect format
                    %specifiers...
                    Eyelink('Message', '%s', chunk);
                end
                
                if(stop)
                    break;
                end
            end
        end
    end
end