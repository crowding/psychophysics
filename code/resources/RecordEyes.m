function initializer = RecordEyes(varargin)
%
% produces an initializer that starts and stops eyelink recording. Should
% only be used when eyelink has been acquired by another initializer.
args = varargin;
initializer = setnargout(2, @(varargin) doRecordEyes(args{:}, varargin{:}));

    function [release, details] = doRecordEyes(details) %FIXME: consolidate struct input, currying, named-argument behavior.
        if (Eyelink('IsConnected') == details
            status = Eyelink('StartRecording');
        end
        if status ~= 0
            error('RecordEyes:error', 'status %d starting recording', status);
        end

        release = @doRelease;
        function doRelease
            status = Eyelink('StopRecording');
            if status ~= 0
                error('RecordEyes:error', 'status %d stopping recording', status);
            end
        end
    end
end