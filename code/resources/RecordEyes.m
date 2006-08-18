function initializer = RecordEyes(varargin)
%
% produces an initializer that starts and stops eyelink recording. Should
% only be used when eyelink has been acquired by another initializer.
%
% expects the 'el' eyelink initialization struct as part of its input struct.
initializer = setnargout(2, currynamedargs(@doRecordEyes, varargin{:}));

    function [release, details] = doRecordEyes(details) %FIXME: consolidate struct input, currying, named-argument behavior.
        disp(details)
        switch Eyelink('IsConnected')
            case details.el.connected
                status = Eyelink('StartRecording');
                if status ~= 0
                    error('RecordEyes:error', 'status %d starting recording', status);
                end
                release = @doRelease;
            case details.el.dummyconnected
                %do nothing
                release = @noop;
            otherwise
                error('RecordEye:notConnected', 'eyelink not connected', status);
        end

        release = @doRelease;
        function doRelease
            status = Eyelink('StopRecording');
            if status ~= 0
                error('RecordEyes:error', 'status %d stopping recording', status);
            end
        end
        
        function noop
            %do nothing
        end
    end
end