function this = EyeEvents()
%function this = EyeEvents(details_)
%
% Makes an object for tracking eye movements, and
% triggering calls when the eye moves in and out of screen-based regions.

[this, spaceEvents_] = inherit(SpaceEvents(), public(@sample, @initializer));

details_ = [];
mouseOffset = [0, 0];

%----- method definition -----
    function [x, y, t] = sample
        if details_.dummy
            [x, y, buttons] = GetMouse(details_.window);
            t = GetSecs();
            if any(buttons) %simulate blinking
                x = NaN;
                y = NaN;
            end
            return;
        else
            %otherwise...
            %obtain a new sample from the eye.
            %poll on the presence of a sample (FIXME do I really want to do this?)
            if Eyelink('NewFloatSampleAvailable') == 0;
                x = NaN;
                y = NaN;
                t = GetSecs();
                return;
            end

            % Probably don't need to do this eyeAvailable check every
            % frame. Profile this call?
            eye = Eyelink('EyeAvailable');
            switch eye
                case details_.el.BINOCULAR
                    error('eyeEvents:binocular',...
                        'don''t know which eye to use for events');
                case details_.el.LEFT_EYE
                    eyeidx = 1;
                case details_.el.RIGHT_EYE
                    eyeidx = 2;
            end

            sample = Eyelink('NewestFloatSample');
            x = sample.gx(eyeidx);
            y = sample.gy(eyeidx);
            if x == -32768 %no position -- blinking?
                x = NaN;
                y = NaN;
            end
            t = (sample.time - details_.clockoffset) / 1000;
        end
    end

    function i = initializer(varargin)
        i = joinResource(spaceEvents_.initializer(varargin{:}), RecordEyes(), @doInit);
        
        function [release, details] = doInit(details)
            details_ = details;
            release = @noop;
        end
    end


end