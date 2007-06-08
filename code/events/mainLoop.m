function this = mainLoop(graphics, triggers, varargin)

defaults = struct...
    ( 'log', @noop ...
    , 'skipFrames', 1 ...
    , 'dontsync', 0 ...
    , 'slowmo', 0 );
params_ = namedargs(defaults, varargin{:});

%The main loop which controls presentation of a trial. There are three
%output arguments, main, drawing, and events, which used to be separate
%objects in separate files, but were tied together for speed.
%
%It also used ot let you dynamically add and remove drawing objects and
%triggers, but this has been disable due to massive speed problems with
%matlab's nested functions.
%
%The main loop allows you to start and stop.

%----- constructed objects -----
this = public(@go, @stop, @drawTriggers);

%instance variables
go_ = 0; % flags whether the main loop is running

%the list of graphics components, restricted to the interface we use
graphics_ = interface(struct('draw', {}, 'update', {}, 'init', {}), graphics);
ng_ = numel(graphics_);


%java_ = psychusejava('jvm');

%Our list of triggers.
triggers_ = interface(struct('check', {}, 'draw', {}, 'setLog', {}), triggers);
nt_ = numel(triggers_);

%values used while running in the main loop
toDegrees_ = [];
log_ = [];

badSampleCount_ = 0;
missingSampleCount_ = 0;
goodSampleCount_ = 0;
skipFrameCount_ = 0;

windowLeft_ = 0;
windowTop_ = 0;


%----- methods -----

    function params = go(varargin)
        params = namedargs(params_, varargin{:});
        %run the main loop, collecting events, calling triggers, and
        %redrawing the screen until stop() is called.
        %
        %Initializes the event managers and sets high CPU priority before
        %running.
        params = require(...
            triggerInitializer(params)...
            ,graphicsInitializer()...
            ,highPriority()...
            ,@doGo...
            );
%            ,listenChars()...
        params_ = params;
    end

    function params = doGo(params)
        go_ = 1;
        interval = params.cal.interval;
        hitcount = 0;
        skipcount = 0;
        dontsync = params.dontsync;

        %for better speed in the loop, eschew struct access?
        log = params.log;
        window = params.window;

        lastVBL = Screen('Flip', params.window);
        %the main loop
        while(1)
            % take a sample from the eyetracker and react to it.
            pushEvents(params, lastVBL + interval);

            if ~go_
                break;
            end

            %check for the button press to quit (getChar is useless now!)
            [x, y, buttons] = GetMouse();
            if (buttons(1))
                error('mainLoop:userCanceled', 'user escaped from main loop.');
            end
            %{
            %check for the quit key
            if java_
                if CharAvail() && lower(GetChar()) == 'q'
                    error('mainLoop:userCanceled', 'user escaped from main loop.');
                end
            end
            %}

            %draw all the objects
            for i = 1:ng_
                graphics_(i).draw(window, lastVBL + interval);
            end
            
            [VBL] = Screen('Flip', window, 0, 0, dontsync);
            hitcount = hitcount + 1;

            %count the number of frames advanced and do the
            %appropriate number of drawing.update()s
            if (params.skipFrames)
                frames = round((VBL - lastVBL) / interval);
                skipcount = skipcount + frames - 1;
                skipFrameCount_ = skipFrameCount_ + frames - 1;

                
                if frames > 1
                    log('FRAME_SKIP %d %f %f', frames-1, lastVBL, VBL);
                end

                if frames > 60
                    error('mainLoop:drawingStuck', ...
                        'got stuck doing frame updates...');
                end
            else
                frames = 1;
                if params.slowmo
                    WaitSecs(params.slowmo);
                end
            end

            for i = 1:frames
                %may accumulate error if
                %interval differs from the actual interval...
                %but we're screwed in that case.

                %step forward the frame on all objects
                for i = 1:ng_
                    graphics_(i).update()
                end
            end

            lastVBL = VBL;
        end
        log('FRAME_COUNT %d SKIPPED %d', hitcount, skipcount);
        disp(sprintf('hit %d frames, skipped %d', hitcount, skipcount));
    end

    function stop(x, y, t, next)
        %Stops the main loop. Takes arguments compatible with being called
        %from a trigger.
        %
        %See also mainLoop>go.
        go_ = 0;
    end

    function addGraphic(drawer)
        %Add a graphics object to the display. The object must support the
        %'draw', 'update', and 'init' methods. Objects cannot be added
        %while the main loop is running for performance reasons.
        %
        %Aee also Drawer.
        if go_
            error('mainLoop:modificationWhileRunning',...
                ['adding graphics objects while in the display'...
                'is not supported.']);
        end

        graphics_(ng_+1) = interface(graphics_, finalize(drawer)); %was 15.71/24
        ng_ = ng_ + 1;
    end

    function addTrigger(trigger)
        %Adds a trigger object. Each trigger object is called when an eye
        %movement sample is received.
        %
        %See also Trigger.
        if go_
            error('mainLoop:modification_while_running',...
                'Can''t add triggers while running the main loop. Matlab is too slow. Try again in a different language.');
        end

        triggers_(nt_+1) = interface(triggers_, finalize(trigger));
        nt_ = nt_+1;
    end

    function pushEvents(params, next)
        % Sample the eye and give to sample to all triggers.
        %
        % next: the scheduled next refresh.
        % triggers: the triggers to check. you'd think this would be passed
        % in manually, but lexical scope lookup is very slow for some
        % reason. Hmm. Array reallocation issues?
        %
        % See also Trigger>check.

        if ~go_
            error('mainLoop:notOnline', 'must start spaceEvents before recording');
        end
        [x, y, t] = sample(params);
        [x, y] = toDegrees_(x, y); %convert to degrees (native units)

        %send the sample to each trigger and the triggers will fire if they
        %match

        for i = 1:nt_
            triggers_(i).check(x, y, t, next);
        end
    end

    function [x, y, t] = sample(params)
        %Takes a sample from the eye, or mouse if the eyelink is not
        %connected. Returns x and y == NaN if the sample has invalid
        %coordinates.

        if params.dummy
            [x, y, buttons] = GetMouse();
            x = x - windowLeft_;
            y = y - windowTop_;
            
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
                    case params.el.BINOCULAR
                        error('eyeEvents:binocular',...
                            'don''t know which eye to use for events');
                    case params.el.LEFT_EYE
                        eyeidx = 1;
                    case params.el.RIGHT_EYE
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

                t = (sample.time - params.clockoffset) / 1000;
            end
        end
    end


    function init = graphicsInitializer(varargin)
        %Produces an initializer to be called as we enter the main loop.
        %
        %The initializer prepares all the graphics objects. On completion,
        %the graphics %objects are released.
        %
        %See also require.

        init = currynamedargs(joinResource(graphics_.init), varargin{:});
    end

    function i = triggerInitializer(varargin)
        %at the beginning of a trial, the initializer will be called. It will
        %do things like start the eyeLink recording, and tell every trigger
        %where the log file is.
        %
        %See also require.

        i = currynamedargs(...
                joinResource(...
                    @initLog...
                    ,@initVars...
                    ,RecordEyes()...
                )...
                ,varargin{:}...
            );
    end

    function [release, params] = initLog(params)
        
        toDegrees_ = transformToDegrees(params.cal);

        %now that we are starting an experiment, tell each trigger where to
        %log to.
        for i = 1:nt_
            triggers_(i).setLog(params.log);
        end

        release = @stop;

        function stop
            online_ = 0;
        end
    end


    function [release, params] = initVars(params)
        release = @printSampleCounts;

        badSampleCount_ = 0;
        missingSampleCount_ = 0;
        goodSampleCount_ = 0;
        skipFrameCount_ = 0;
        
        rect = Screen('GlobalRect', params.window);
        windowLeft_ = rect(1);
        windowTop_ = rect(2);
        
        function printSampleCounts
            disp(sprintf('%d good samples, %d bad, %d missing, %d frames skipped', ...
                goodSampleCount_, badSampleCount_, missingSampleCount_, skipFrameCount_));
        end
    end


    function drawTriggers(window, toPixels)
        % draw the trigger areas on the screen for debugging purposes.
        %
        % window - the window identifier
        % toPixels - a function transforming degree coordinates to pixels
        %            (see <a href="matlab:help Calibration/transformToPixels">Calibration/transformToPixels</a>)
        %
        % See also Trigger>draw.

        for i = 1:nt_
            triggers_(i).draw(window, toPixels);
        end
    end

end
