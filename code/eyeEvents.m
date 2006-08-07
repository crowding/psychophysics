function this = EyeEvents(el_, calibration_)
%function this = EyeEvents(el)
%
% Makes an object for tracking eye movements, and
% triggering calls when the eye moves in and out of screen-based regions.
%
% Constructor arguments:
%   'el' the eyelink constants
%   'calibration' the display calibration
%
% complaint:
% (why pass around a bunch of constants as an argument?)

%----- constructor - checks a condition and returns the appropriate event
%----- producer. Note that you don't need a Factory class for this, just
%----- the regular constructor.
connection = Eyelink('IsConnected');
switch connection
    case el_.connected
        this = inherit(SpaceEvents(), public(@sample));
    case el_.dummyconnected
        warning('EyeEvents:usingMouse', 'using mouse movements, not eyes');
        this = MouseEvents();
    otherwise
        error('eyeEvents:not_connected', 'eyelink not connected');
end

%----- method definition -----
    function [x, y, t] = sample
        %obtain a new sample from the eye.
        %poll on the presence of a sample
        while Eyelink('NewFloatSampleAvailable') == 0;

            % FIXME: don't need to do this eyeAvailable check every
            % frame. Profile this.
            eye = Eyelink('EyeAvailable');
            switch eye
                case el_.BINOCULAR
                    error('eyeEvents:binocular',...
                        'don''t know which eye to use for events');
                case el_.LEFT
                    eyeidx = 1;
                case el_.RIGHT
                    eyeidx = 2;
            end

            sample = Eyelink('NewestFloatSample');
            [x, y, t] = deal(...
                sample.gx(eye), sample.gy(eye), sample.time / 1000);
        end
    end

end