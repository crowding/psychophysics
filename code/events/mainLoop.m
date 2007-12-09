function this = mainLoop(varargin)
%function this = mainLoop( ['property', value]* )
%
%The main loop which controls presentation of a trial, and controls the
%events.
%
%Named properties:
%
% graphics -- a cell array of graphics handlers (see the graphics directory)
% events -- a cell array of eye position dispatchers (see the events directory)
% keyboard -- keyboard event dispatchers (see the events directory)
% mouse -- mouse event dispatchers (see the events directory)
%
%It also used to let you dynamically add and remove drawing objects and
%triggers, but this has been taken out due to massive performance problems
%with matlab's nested functions.
%
%The main loop allows you to start and stop.

%% Object properties
defaults_ = struct...
    ( 'log', @noop ...
    , 'skipFrames', 1 ...
    , 'dontsync', 0 ...
    , 'slowdown', 1 ...
    , 'aviout', ''...
    , 'avirect', [] ...
    );

%graphics is a non-generic output method so the list of graphics objects remains.
graphics = {};

%this is old and needs to be generalized.
triggers = {};

%these are old and only for backwards compatibility.
keyboard = {};
mouse = {};

%new hotness, input using a variable list of methods.
input = {};

%support the old mainLoop(graphics, triggers) calling convention
varargin = assignments(varargin, 'graphics', 'triggers');

persistent init__;
this = autoobject(varargin{:});


%% private variables
go_ = 0; % flags whether the main loop is running
toDegrees_ = @noop;

%% methods

    function params = go(varargin)
        params = namedargs(defaults_, varargin{:});
        
        % constructor support for older constructor conventions --
        if ~isempty(triggers) && isempty(input)
            %old-style put all eye movement triggers in 'triggers', new style puts
            %everything there.
            input{end+1} = params.input.eyes;
        end

        if ~isempty(keyboard)
            input{end+1} = params.input.keyboard;
            triggers = {triggers{:} keyboard{:}};
            keyboard = {};
        end

        if ~isempty(mouse)
            input{end+1} = params.input.mouse;
            triggers = {triggers{:} mouse{:}};
            mouse = {};
        end

        %run the main loop, collecting events, calling triggers, and
        %redrawing the screen until stop() is called.
        %
        %Initializes the event managers and sets high CPU priority before
        %running.
        params = require...
            ( triggerInitializer(params)...
            , graphicsInitializer()...
            , highPriority()...
            , startInput()...
            , @doGo_...
            );
        %%% PERF NOTE between the end of doGo and here is a major
        %%% bottleneck...

    end

    function params = doGo_(params)
        ng = numel(graphics);
        nt = numel(triggers);
        go_ = 1;
        interval = params.cal.interval;
        VBLStartline = params.screenInfo.VBLStartline;
        VBLEndline = params.screenInfo.VBLEndline;
        flipInterval = params.screenInterval;
        skipcount = 0;
        slowdown = max(params.slowdown, 1);
        
        %for better speed in the loop, eschew struct access?
        log = params.log;
        window = params.window;
        aviout_ = params.aviout;
        if (aviout_)
            aviobj = avifile(aviout_, 'fps', 1 / interval);
        end

        VBL = Screen('Flip', params.window) / slowdown; %hit refresh -1
        
        %if this is correct we should be in refresh 0 right now?
        %Synchronize what needs synchronizing...
        for i = 1:numel(input)
            input(i).sync(-1);
        end
        
        refresh = 0;    %the first flip in the loop is flip 0
                        %(the first that draws anything is flip 1)

        while(1)
            %The loop is: Flip, Draw, Update, run Events.
            %Draw happens right after Flip, to keep its pipeline as full
            %as possible. This minimizes frame skipping but has a downside:
            %
            %Event handlers are preparing things for frame X+2 while frame
            %X is at the display. It also takes one extra frame to recover
            %from a drop.
            
            %-----Flip phase: Flip the screen buffers and note the time at
            %which the change occurred.
            prevVBL = VBL;
            
            deadline = (VBL + interval) * slowdown - interval/2;
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', window, deadline, [], 1);
            beampos = Screen('GetWindowInfo', params.window, 1);
            %Estimate of when the next blank happens
            VBL = FlipTimestamp + (VBLStartline-beampos)/VBLEndline*flipInterval;
            
            if (deadline > VBL)
                %figure it hit anyway, since this only happens in slowdown
                %mode.
                VBL = VBL + ceil((deadline - VBL) * interval) + interval;
            end

            VBL = VBL / slowdown;
            
            if (aviout_)
                frame = Screen('GetImage', window);
                size(frame)
                class(frame)
                aviobj = addframe(aviobj, Screen('GetImage', window));
            end

            if (~go_)
                %the loop test is here, so that the final frame gets drawn
                %to the screen.
                break;
            end
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
                %with the option to produce a aviout rendering.
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
            s = struct('next', VBL + 2*interval, 'refresh', refresh);

            %generic events...
            for i = 1:numel(input)
                s = input(i).input(s);
            end
            
            for i = 1:numel(triggers)
                triggers(i).check(s);
            end
        end

        log('FRAME_COUNT %d SKIPPED %d', refresh, skipcount);
        disp(sprintf('ran for %d frames, skipped %d', refresh, skipcount));
        if (aviout_)
            close(aviobj); %TODO make this into a REQUIRE
        end
    end

    function stop(s)
        %Stops the main loop. Takes arguments compatible with being called
        %from a trigger.
        %
        %See also mainLoop>go.
        go_ = 0;
    end

    function i = triggerInitializer(varargin)
        %at the beginning of a trial, the initializer will be called. It will
        %do things like start the eyeLink recording, and tell every trigger
        %where the log file is.
        %
        %See also require.
        triggers = interface(struct('check', {}, 'setLog', {}, 'init', {}), triggers);
        
        i = currynamedargs(...
                joinResource...
                    ( @initLog...
                    , @initVars...
                    , triggers.init...
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
        release = @noop;
        toDegrees_ = transformToDegrees(params.cal);
    end

    function init = graphicsInitializer(varargin)
        %Produces an initializer to be called as we enter the main loop.
        %
        %The initializer prepares all the graphics objects. On completion,
        %the graphics %objects are released.
        %
        %See also require.
        graphics = interface(struct('draw',  {}, 'update', {}, 'init',   {}), graphics);
        
        init = currynamedargs(joinResource(graphics.init), varargin{:});
    end

    function init = startInput()
        input = interface(struct('input', {}, 'begin', {}, 'sync', {}), input);
        init = joinResource(input.begin);
    end
        
    function drawTriggers(window, toPixels)
        % draw the trigger areas on the screen for debugging purposes.
        %
        % window - the window identifier
        % toPixels - a function transforming degree coordinates to pixels
        %            (see <a href="matlab:help Calibration/transformToPixels">Calibration/transformToPixels</a>)
        %
        % See also Trigger>draw.

        for i = 1:numel(triggers)
            triggers(i).draw(window, toPixels);
        end
    end

end
