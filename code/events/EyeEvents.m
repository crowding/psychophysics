function this = EyeEvents(details_)
%function this = EyeEvents(details_)
%
% Makes an object for tracking eye movements, and
% triggering calls when the eye moves in and out of screen-based regions.
%
% struct argument with fields:
%   'cal' the display calibration
%   'el' the eyelink constants
%   'dummy' true if connected in dummy mode
%   'clockoffset' the clock offset in milliseconds (will be subtracted from
%   the eyelink data)

%----- constructor - checks a condition and returns the appropriate event
%----- producer. Note that you don't need a Factory class for this, just
%----- the regular constructor.
if details_.dummy
    warning('EyeEvents:usingMouse', 'using mouse movements, not eyes');
    this = MouseEvents(details_);
else
    [this, spaceEvents_] = inherit(SpaceEvents(details_), public(@sample, @start, @stop));
end

%----- method definition -----
    function [x, y, t] = sample
        %obtain a new sample from the eye.
        %poll on the presence of a sample (FIXME do I really want to do this?)
        while Eyelink('NewFloatSampleAvailable') == 0;
        end

        % FIXME: Probably don't need to do this eyeAvailable check every
        % frame. Profile this call?
        eye = Eyelink('EyeAvailable');
        switch eye
            case details_.el_.BINOCULAR
                error('eyeEvents:binocular',...
                    'don''t know which eye to use for events');
            case details_.el_.LEFT_EYE
                eyeidx = 1;
            case details_.el_.RIGHT_EYE
                eyeidx = 2;
        end

        sample = Eyelink('NewestFloatSample');
        [x, y, t] = deal(...
            sample.gx(eyeidx), sample.gy(eyeidx), (sample.time - details.clockoffset) / 1000);
    end

    function start()
        spaceEvents_.start();
        status = Eyelink('StartRecording');
        if status ~= 0
            error('EyeEvents:errorInStart', 'status %d starting recording', status);
        end
    end

    function stop()
        try
            status = Eyelink('StopRecording');
            if status ~= 0
                error('EyeEvents:errorInStart', 'status %d starting recording', status);
            end
        catch
            spaceEvents_.stop();
            rethrow
        end
        %duplicated call-think about how to do chained destructor methods
        spaceEvents_.stop();
    end
end
