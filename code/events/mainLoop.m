function this = mainLoop(graphics, triggers, varargin)
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
    , 'slowdown', 1 );

if ~exist('graphics', 'var')
    graphics = {};
end
if ~exist('triggers', 'var')
    triggers = {};
end

keyboard = {};
mouse = {};

this = autoobject(varargin{:});

%----- constructed objects -----

%instance variables
go_ = 0; % flags whether the main loop is running
nt_ = 0;
toDegrees_ = [];

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
        slowdown = max(params.slowdown, 1);
        
        %for better speed in the loop, eschew struct access?
        log = params.log;
        window = params.window;

        VBL = Screen('Flip', params.window) / slowdown;
        prevVBL = VBL - interval; %meaningless fakery
        refresh = 1;    %the first refresh we draw is refresh 1.
        
        %the main loop
        while(go_)
            %The loop is: Draw, Update, run Events, and Flip.
            %Draw happens right after Flip, to give as much time
            %to the graphics card as possible. This minimizes frame
            %skipping but has a downside:
            %event handlers are preparing things for frame X+2 while frame
            %X is at the display. It also takes one extra frame to recover
            %from a drop.
            
            %-----Draw phase: Draw all the objects for the next refresh.
            for i = 1:ng
                graphics(i).draw(window, VBL + interval);
            end

            Screen('DrawingFinished', window);
            
            %-----Update phase: 
            %reacts to the difference in VBL times, and updates
            %the number of refreshes.
            if (params.skipFrames)
                steps = round((VBL - prevVBL) / interval);
                skipcount = skipcount + steps - 1;

                if steps > 1
                    %The log entry notes that the refresh X, intended for
                    %time T, was actually shown at refresh X', T'. Because 
                    %we've already drawn the next frame, refresh (X+1, T+dt)
                    %will probably be shown as the slot (X'+1, T'+dt). But
                    %following that we will catch up and refresh
                    %X'+2,t'+2dt should happen on schedule. (This is mostly
                    %academic: before collecting data 
                    %you will optimize your code until there are
                    %no frame skips under normal conditions.
                    %Logged fields: Number of skipped frames, VBL of last
                    %frame before skip, VBL of frame just delivered,
                    %refresh index of... the frame that has been delayed
                    %(work out what it means later.)
                    log('FRAME_SKIP %d %f %f %d', steps-1, prevVBL, VBL, refresh);
                end

                if steps > 60
                    error('mainLoop:drawingStuck', ...
                        'got stuck doing frame updates...');
                end
            else
                %pretend there are not skips.
                %TODO: be even more faking about this -- in the events and
                %with the option to produce a quicktime rendering.
                steps = 1;
            end
            
            %tell each graphic object how far to step.
            for i = 1:ng
                graphics(i).update(steps);
            end

            %Events phase:
            %
            %Having finished drawing this refresh, Starting with these
            %Event handlers we are now working on the next
            %refresh.
            refresh = refresh + steps;

            %We currently take events from eye movements, keyboard and the
            %mouse; each event type calls up its own list of event checkers.
            %This may be generalised to a variety of event sources.

            %Eye movement events...
            pushEvents(params, VBL + 2*interval, refresh)
            
            %Mouse events...
            if ~isempty(mouse)
                [m.x, m.y, m.buttons] = GetMouse();
                m.t = GetSecs() / slowdown;
                [m.x_deg, m.y_deg] = toDegrees_(m.x, m.y);
                m.next = VBL + 2*interval;
                m.refresh = refresh;
                for i = mouse(:)'
                    i.check(m);
                end
            end
            
            %Keyboard events...
            if ~isempty(keyboard)
                [k.keyIsDown, k.t, k.keyCode] = KbCheck();
                k.t = k.t / slowdown;
                k.next = VBL + 2*interval;
                k.refresh = refresh;
                for i = keyboard(:)'
                    i.check(k);
                end
            end

            %-----Flip phase: Flip the screen buffers and note the time at
            %which the change occurred.
            prevVBL = VBL;
            VBL = Screen('Flip', params.window, (VBL + interval) * slowdown - interval/2) / slowdown;
        end
        log('FRAME_COUNT %d SKIPPED %d', refresh, skipcount);
        disp(sprintf('ran for %d frames, skipped %d', refresh, skipcount));
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

        for i = 1:numel(triggers)
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
            
            t = GetSecs() / params.slowdown;
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
                t = GetSecs() / params.slowdown;
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

                t = (sample.time - params.clockoffset) / 1000 / params.slowdown;
            end
        end
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
        %now that we are starting an experiment, tell each trigger where to
        %log to.
        
        for i = triggers(:)'
            i.setLog(params.log);
        end

        for i = keyboard(:)'
            i.setLog(params.log);
        end

        for i = mouse(:)'
            i.setLog(params.log);
        end

        release = @stop;

        function stop
        end
    end

    function [release, params] = initVars(params)
        release = @noop;

        toDegrees_ = transformToDegrees(params.cal);
        rect = Screen('GlobalRect', params.window);
        windowLeft_ = rect(1);
        windowTop_ = rect(2);
    end


    function init = graphicsInitializer(varargin)
        %Produces an initializer to be called as we enter the main loop.
        %
        %The initializer prepares all the graphics objects. On completion,
        %the graphics %objects are released.
        %
        %See also require.
        graphics = interface(struct('draw',  {}, 'update', {}, 'init',   {}), graphics);
        triggers = interface(struct('check', {}, 'draw',   {}, 'setLog', {}), triggers);
        keyboard = interface(struct('check', {}, 'setLog', {}, 'init',   {}), keyboard);
        mouse    = interface(struct('check', {}, 'setLog', {}, 'init',   {}), mouse);
        
        init = currynamedargs(joinResource(graphics.init, keyboard.init, mouse.init), varargin{:});
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
