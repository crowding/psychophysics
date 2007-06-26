function this = mainLoop(graphics, triggers)
%function this = mainLoop(graphics, triggers)
%
%The main loop which controls presentation of a trial. There are three
%output arguments, main, drawing, and events, which used to be separate
%objects in separate files, but were tied together for speed.
%
%It also used to let you dynamically add and remove drawing objects and
%triggers, but this has been disable due to massive speed problems with
%matlab's nested functions.
%
%The main loop allows you to start and stop.

defaults_ = struct...
    ( 'log', @noop ...
    , 'skipFrames', 1 ...
    , 'dontsync', 0 ...
    , 'slowmo', 0 );

if ~exist('graphics', 'var')
    graphics = {};
end
if ~exist('triggers', 'var')
    triggers = {};
end

this = autoobject();

%----- constructed objects -----

%instance variables
go_ = 0; % flags whether the main loop is running
nt_ = 0;
toDegrees_ = [];

%java_ = psychusejava('jvm');

%values used while running in the main loop

badSampleCount = 0;
missingSampleCount = 0;
goodSampleCount = 0;
skipFrameCount = 0;

windowLeft_ = 0;
windowTop_ = 0;

%----- methods -----

    function params = go(varargin)
        params = namedargs(defaults_, varargin{:});
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
    end

    function params = doGo(params)
        ng = numel(graphics);
        nt_ = numel(triggers);
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
            %before the change to structs, this line was 9.3% of the main
            %loop.
            %pushEvents(params, lastVBL + interval);
            pushEvents(params, lastVBL + interval, hitcount+skipcount)
            
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
            for i = 1:ng
                graphics(i).draw(window, lastVBL + interval);
            end
            
            [VBL] = Screen('Flip', window, 0, 0, dontsync);
            hitcount = hitcount + 1;

            %count the number of frames advanced and do the
            %appropriate number of drawing.update()s
            if (params.skipFrames)
                frames = round((VBL - lastVBL) / interval);
                skipcount = skipcount + frames - 1;
                skipFrameCount = skipFrameCount + frames - 1;

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

            %update the graphics objects for having played a frame
            for i = 1:ng
                graphics(i).update(frames);
            end

            lastVBL = VBL;
        end
        log('FRAME_COUNT %d SKIPPED %d', hitcount, skipcount);
        disp(sprintf('hit %d frames, skipped %d', hitcount, skipcount));
    end

    function stop(s)
        %Stops the main loop. Takes arguments compatible with being called
        %from a trigger.
        %
        %See also mainLoop>go.
        go_ = 0;
    end

    function pushEvents(params, next, refresh)
        % Send information about the present state of the world to all 
        % triggers and allow them to fire if they wish.
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

        %at the outset the datra contains these values:
        %'x', the last recorded eye x-position.
        %'y', the last recorded eye y-position.
        %'t', the time that the eye position was recorded
        %'next', the scheduled time of the next eye refresh.
        %'refresh', which counts the screen refreshes that have occurred
        %(including those skipped.)
        s = struct('x', x, 'y', y, 't', t, 'next', next, 'refresh', refresh);
        %send the sample to each trigger and the triggers will fire if they
        %match.

        for i = 1:nt_
            triggers(i).check(s);
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
                badSampleCount = badSampleCount + 1;
            else
                goodSampleCount = goodSampleCount + 1;
            end
        else
            %obtain a new sample from the eye.
            if Eyelink('NewFloatSampleAvailable') == 0;
                x = NaN;
                y = NaN;
                t = GetSecs();
                missingSampleCount = missingSampleCount + 1;
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
                    badSampleCount = badSampleCount + 1;
                    x = NaN;
                    y = NaN;
                else
                    goodSampleCount = goodSampleCount + 1;
                end

                t = (sample.time - params.clockoffset) / 1000;
            end
        end
    end


    function i = triggerInitializer(varargin)
        %at the beginning of a trial, the initializer will be called. It will
        %do things like start the eyeLink recording, and tell every trigger
        %where the log file is.
        %
        %See also require.
        
        triggers = interface(struct('check', {}, 'draw', {}, 'setLog', {}), triggers);
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
        %now that we are starting an experiment, tell each trigger where to
        %log to.
        for i = triggers(:)'
            i.setLog(params.log);
        end

        release = @stop;

        function stop
        end
    end

    function [release, params] = initVars(params)
        release = @printSampleCounts;

        toDegrees_ = transformToDegrees(params.cal);
        
        badSampleCount = 0;
        missingSampleCount = 0;
        goodSampleCount = 0;
        skipFrameCount = 0;
        
        rect = Screen('GlobalRect', params.window);
        windowLeft_ = rect(1);
        windowTop_ = rect(2);
        
        function printSampleCounts
            disp(sprintf('%d good samples, %d bad, %d missing, %d frames skipped', ...
                goodSampleCount, badSampleCount, missingSampleCount, skipFrameCount));
        end
    end


    function init = graphicsInitializer(varargin)
        %Produces an initializer to be called as we enter the main loop.
        %
        %The initializer prepares all the graphics objects. On completion,
        %the graphics %objects are released.
        %
        %See also require.
        graphics = interface(struct('draw', {}, 'update', {}, 'init', {}), graphics);
        init = currynamedargs(joinResource(graphics.init), varargin{:});
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
            triggers(i).draw(window, toPixels);
        end
    end

end
