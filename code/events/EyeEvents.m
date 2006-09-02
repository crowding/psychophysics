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

%triggers_ = cell(0); %ideal
triggers_ = struct('getId', {}, 'check', {}, 'draw', {}, 'setLog', {}); %middle

transform_ = [];
online_ = 0;
log_ = [];

this = final(@add, @remove, @update, @clear, @draw, @initializer, @sample, @getTriggers);

details_ = [];

badSampleCount_ = 0;
missingSampleCount_ = 0;
goodSampleCount_ = 0;



%----- method definition -----

    function t = getTriggers()
        t = triggers_;
    end

    function add(trigger)
        if online_
            error('SpaceEvents:modification_while_running',...
                'Can''t add or remove triggers while running. Matlab is too slow. Try again in a different language.');
        end
        %adds a trigger object.
        %
        %See also Trigger.

        %triggers_{end + 1} = trigger; %ideal
        triggers_(end+1) = interface(triggers_, trigger); %middle
    end


    function remove(trigger)
        %Removes a trigger object.
        %
        %See also Trigger.
        if online_
            error('SpaceEvents:modification_while_running',...
                'Can''t add or remove triggers while running.');
        end


        searchid = trigger.getId();
        %found = find(cellfun(@(x)x.getId() == searchid, triggers_)); %ideal
        found = find(arrayfun(@(x)x.getId() == searchid, triggers_)); %middle
        %found = find(id_ == searchid); %ugly
        if ~isempty(found)
            %triggers_(found(1)) = []; %ideal
            triggers_(found(1)) = []; %middle
        else
            warning('SpaceEvents:noSuchItem',...
                'tried to remove nonexistent item with id %d', searchid);
        end
    end

    function clear
        %Removes all triggers.

        %triggers_(:) = []; %ideal
        triggers_(:) = []; %middle

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
        [x, y] = transform_(x, y); %convert to degrees (native units)

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
        %do things like start the eyeLink recording.
        %
        %See also require.

        i = JoinResource(currynamedargs(@initLog, varargin{:}),...
            @initSampleCounts, RecordEyes());
    end


    function [release, details] = initLog(details)
        transform_ = transformToDegrees(details.cal);
        online_ = 1;

        %now that we are starting an experiment, tell each trigger where to
        %log to.
        for t = triggers_
            t.setLog(details.log);
        end

        release = @stop;

        function stop
            online_ = 0;
        end
    end


    function [release, details] = initSampleCounts(details)
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

end