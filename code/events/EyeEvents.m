function this = EyeEvents()
%function this = EyeEvents()
%
% Makes an object for tracking eye movements, and
% triggering calls when the eye moves in and out of screen-based regions.

%-----private data-----

%The event-oriented idea is based around a list of triggers. The
%lists specify a criterion that is to be met and a function to be
%called when the criterion is met.

%there are alternatives for how to maintain the trigger list. The
%datatype of the list appears to be a source of much overhead when calling
%update. Right now the middle alternative seems fastest, for whatever
%reason.

this = final(@add, @update, @initializer, @sample, @getTriggers);

%Our list of triggers.
triggers_ = struct('check', {}, 'draw', {}, 'setLog', {});

%values used while running in the main loop
online_ = 0;
toDegrees_ = [];
log_ = [];
params_ = [];

badSampleCount_ = 0;
missingSampleCount_ = 0;
goodSampleCount_ = 0;


%----- method definition -----

    function t = getTriggers()
        t = triggers_;
    end

    function add(trigger)
        %Adds a trigger object. Each trigger object is called when an eye
        %movement sample is received.
        %
        %See aslo Trigger.
        if online_
            error('SpaceEvents:modification_while_running',...
                'Can''t add triggers while running. Matlab is too slow. Try again in a different language.');
        end

        %triggers_{end + 1} = trigger; %ideal
        triggers_(end+1) = interface(triggers_, trigger); %middle
    end

    function update(triggers, next)
        % Sample the eye and give to sample to all triggers.
        %
        % next: the scheduled next refresh.
        % triggers: the triggers to check. you'd think this would be passed
        % in manually, but lexical scope lookup is very slow for some
        % reason. Hmm. Array reallocation issues?
        %
        % See also Trigger>check.

        if ~online_
            error('spaceEvents:notOnline', 'must start spaceEvents before recording');
        end
        [x, y, t] = sample();
        [x, y] = toDegrees_(x, y); %convert to degrees (native units)

        %send the sample to each trigger and the triggers will fire if they
        %match

        for trig = triggers %ideal, middle
            %trig{:}.check(x, y, t, next); %ideal
            trig.check(x, y, t, next); %middle
        end
    end

    function draw(window, toPixels)
        % draw the trigger areas on the screen for debugging purposes.
        %
        % window - the window identifier
        % toPixels - a function transforming degree coordinates to pixels
        %            (see <a href="matlab:help Calibration/transformToPixels">Calibration/transformToPixels</a>)
        %
        % See also Trigger>draw.

        for trig = triggers_ %ideal, middle
            %trig{i}.draw(window, toPixels); %ideal
            trig.draw(window, toPixels); %middle
        end
    end

    function i = initializer(varargin)
        %at the beginning of a trial, the initializer will be called. It will
        %do things like start the eyeLink recording, and tell every trigger
        %where the log file is.
        %
        %See also require.

        i = JoinResource(...
            currynamedargs(@initLog, varargin{:})...
            ,@initSampleCounts...
            ,RecordEyes()...
            );
    end


    function [release, params] = initLog(params)
        toDegrees_ = transformToDegrees(params.cal);
        online_ = 1;

        %now that we are starting an experiment, tell each trigger where to
        %log to.
        for t = triggers_
            t.setLog(params.log);
        end

        release = @stop;

        function stop
            online_ = 0;
        end
    end


    function [release, params] = initSampleCounts(params)
        params_ = params;
        release = @printSampleCounts;

        badSampleCount_ = 0;
        missingSampleCount_ = 0;
        goodSampleCount_ = 0;

        function printSampleCounts
            disp(sprintf('%d good samples, %d bad, %d missing', ...
                goodSampleCount_, badSampleCount_, missingSampleCount_));
        end
    end



    function [x, y, t] = sample
        %Takes a sample from the eye, or mouse if the eyelink is not
        %connected. Returns x and y == NaN if the sample has invalid
        %coordinates.

        if params_.dummy
            [x, y, buttons] = GetMouse(params_.window);
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
                    case params_.el.BINOCULAR
                        error('eyeEvents:binocular',...
                            'don''t know which eye to use for events');
                    case params_.el.LEFT_EYE
                        eyeidx = 1;
                    case params_.el.RIGHT_EYE
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

                t = (sample.time - params_.clockoffset) / 1000;
            end
        end
    end

end