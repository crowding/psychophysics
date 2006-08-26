function this = EyeEvents()
%function this = EyeEvents(details_)
%
% Makes an object for tracking eye movements, and
% triggering calls when the eye moves in and out of screen-based regions.
%
% See also SpaceEvents.

[this, spaceEvents_] = inherit(SpaceEvents(), public(@sample, @initializer));

details_ = [];

badSampleCount_ = 0;
missingSampleCount_ = 0;
goodSampleCount_ = 0;

%----- method definition -----
    function [x, y, t] = sample
        %Takes a sample from the eye, or mouse if the eyelink is not
        %connected. Returns x and y == NaN if the sample has invalid
        %coordinates.
        
        if details_.dummy
            [x, y, buttons] = GetMouse(details_.window);
            t = GetSecs();
            if any(buttons) %simulate blinking
                x = NaN;
                y = NaN;
                badSampleCount_ = badSampleCount_ + 1;
            else
                goodSampleCount_ = goodSampleCount_ + 1;
            end
        else
            %obtain a new sample from the eye.
            if Eyelink('NewFloatSampleAvailable') == 0;
                x = NaN;
                y = NaN;
                t = GetSecs();
                missingSampleCount_ = missingSampleCount_ + 1;
            else
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
                    badSampleCount_ = badSampleCount_ + 1;
                    x = NaN;
                    y = NaN;
                else
                    goodSampleCount_ = goodSampleCount_ + 1;
                end
                
                t = (sample.time - details_.clockoffset) / 1000;
            end
        end
    end

    function i = initializer(varargin)
        %Produces an initializer which measures the eyelink's clock offset,
        %and starts the eyelink recording a trial.
        %
        %When the initializer is released, a count of the good, bad, and
        %missing sampled is printed.
        %
        %The initializer requires 'el' and 'dummy' values to be given.
        %
        %See also require.
        i = joinResource(spaceEvents_.initializer(varargin{:}), RecordEyes(), @doInit);
        
        function [release, details] = doInit(details)
            details_ = details;
            release = @printSampleCounts;
            
            badSampleCount_ = 0;
            missingSampleCount_ = 0;
            goodSampleCount_ = 0;
            
            function printSampleCounts
                disp(sprintf('%d good samples, %d bad, %d missing', ...
                    goodSampleCount_, badSampleCount_, missingSampleCount_));
            end
        end
    end
end