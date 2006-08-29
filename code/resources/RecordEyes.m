function initializer = RecordEyes(varargin)
%
% produces an initializer that starts and stops eyelink recording. Should
% only be used when eyelink has been acquired by another initializer.
%
% expects the 'el' eyelink initialization struct as a field of its input
% struct, as well as a 'dummy' field.
%
% Will do a clock offset measurement between the PC and the Eyelink computer
% and store the measured value (in milliseconds) to a 'clockoffset' field.
%
% The measurement appars to be precise (repeatable) within a stdev less 
% 50 microseconds.
%
% It's a good idea to do this measurement per trial, since the Eyelink and PC
% clocks will drift with respect to each other over time. Later analysis
% might try to adjust for that clock drift...

initializer = currynamedargs(...
    joinResource(@doClockSync, @doRecordEyes),...
    varargin{:});

    function [release, details] = doClockSync(details)
        [offset, measured] = getclockoffset(details);
        
        details.clockoffset = offset;
        details.clockoffsetmeasured = measured;
        
        %initializer that determines the clock offset between eyelink and
        %local system time.
        %Requires input structure with fields 'el' (eyelink defaults) and
        %'dummy' (connection type). 

        release = @noop;

        function noop
        end
    end

    function [release, details] = doRecordEyes(details)
        %start/stop the eyes recording.
        if details.dummy
            %do nothing
            release = @noop;
        else
            %Eyelink('StartRecording');
            Eyelink('StartRecording');
            pause(0.1); %pause to allow eyelink to start sending up data?
            
            %{
            % StartRecording is supposed to return a status value, but it
            % doesn't seem to.
            status = Eyelink('StartRecording');
            if status ~= 0
                error('RecordEyes:error', 'status %d starting recording', status);
            end
            %}
            release = @doRelease;
        end

        function doRelease
            Eyelink('StopRecording');
            %{
            %again, the eyelink is supposed to give us a status value, but
            %doesn't.
            
            status = Eyelink('StopRecording');
            if status ~= 0
                error('RecordEyes:error', 'status %d stopping recording', status);
            end
            %}
        end

        function noop
        end
    end



end
