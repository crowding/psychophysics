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

            chunksize = 200;
            %the eyelink logs mesages with a maximum length of 200 chars,
            %so we should wrap longer messages (placing a backslash at the
            %end of message as reminder) into 299 char blocks.
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
                    try
                        %the eyelink toolbox is very picky and will crash eveything if
                        %the string is too long or contains incorrect format
                        %specifiers...
                        status = Eyelink('Message', '%s', chunk);
                        
                        %generally we want to keep logging to the file when
                        %these may be a problem with the eyelink
                        if status ~= 0
                            warning('status %d logging to eyelink', status);
                            fprintf(file_, 'WARNING status %d logging to eyelink\n', status);
                        end
                    catch
                        e = lasterr;
                        warning('openLog:eyelinkException', 'error logging to eyelink: %s', e);
                        fprintf(file_, 'WARNING error logging to eyelink: %s\n', e);
                    end
                end
                
                if(stop)
                    break;
                end
            end
        end
    end
end