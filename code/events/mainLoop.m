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
        hasBeampos = logical(params.screenInfo.VideoRefreshFromBeamposition);
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
        
        %if this is correct the next VBL should mark refresh 0
        %Synchronize what needs synchronizing...
        for i = 1:numel(input)
            input(i).sync(-1);
        end
        
        refresh = 0;    %the first flip in the loop is refresh 0
                        %(the first that draws anything is flip 1)

        while(1)
            %The loop is: Flip, Update, Draw, run Events.
            %Draw happens right after Flip, to keep its pipeline as full
            %as possible. This minimizes frame skipping but has a downside:
            %
            %Event handlers are preparing things for frame X+2 while frame
            %X is at the display. It also takes one extra frame to recover
            %from a drop.
            
            %Note this is like loops 2/4 in the flip timing test...what of
            %loop 3?
            
            %-----Flip phase: Flip the screen buffers and note the time at
            %which the change occurred.
            prevVBL = VBL;
            
            if (hasBeampos)
                [tmp, tmp, FlipTimestamp]...
                    = Screen('Flip', window, [], [], 1);
                beampos = Screen('GetWindowInfo', params.window, 1);
                %Estimate of when the next blank happens
                VBL = FlipTimestamp/slowdown + (VBLStartline-beampos)/VBLEndline*flipInterval;
                skipped = round((VBL/slowdown - prevVBL) / flipInterval) - 1;

                %FIXME this is prob. wrong in slowdown
                
                %if we hit ahead of schedule adjust the VBL estimate.
                if skipped < 0
                    VBL = VBL - flipInterval * skipped;
                    skipped = 0;
                end
            else
                %alternate routine for lack of beampos, not quite as high
                %throughput due to the scheduled flip.
                Screen('Flip', params.window, prevVBL*slowdown + (slowdown-0.9)*interval, [], 1);
                info = Screen('getWindowInfo', params.window);
                
                VBL = info.LastVBLTime/slowdown; %FIXME this is def wrong in slowdown...
                
                skipped = round((VBL - prevVBL) / flipInterval);
                
                if skipped <= 0
                    VBL = VBL - flipInterval*skipped + flipInterval; 
                    skipped = 0;
                else
                    VBL = VBL + interval;
                end
            end
                
            
            if (aviout_)
                frame = Screen('GetImage', window);
                size(frame)
                class(frame)
                aviobj = addframe(aviobj, Screen('GetImage', window));
            end
            
            %-----Update phase: 
            %reacts to the difference in VBL times, and updates
            %the number of refreshes.
            if (params.skipFrames)
                if skipped > 0
                    %Logged fields:
                    %Logged fields: Number of skipped frames, VBL of last
                    %frame before skip, VBL of delayed frame just shown,
                    %refresh index of the same frame
                    log('FRAME_SKIP %d %f %f %d', skipped, prevVBL, VBL, refresh);
                end

                if skipped >= 60
                    error('mainLoop:drawingStuck', ...
                        'got stuck doing frame updates...');
                end
            else
                %pretend there are not skips, even in timestamps.
                %TODO: be even more faking about this -- in the events and
                %with the option to produce a aviout rendering.
                skipped = 0;
                VBL = prevVBL + flipInterval;
            end
            
            %tell each graphic object how far to step.
            for i = 1:ng
                graphics(i).update(skipped + 1);
            end

            %Events phase:
            %
            %Having finished drawing this refresh, Starting with these
            %Event handlers we are now working on the next
            %refresh.
            refresh = refresh + skipped + 1;

            if (~go_)
                %the loop test is here, so that the final frame gets
                %flipped to the screen.
                break;
            end
            %-----Draw phase: Draw all the objects for the next refresh.
            %To begin drawing, the preious frame must be on its way to the
            %screen, hso here is an opportunity to wait...
            WaitSecs(GetSecs - VBL);
            
            for i = 1:ng
                graphics(i).draw(window, VBL + flipInterval);
            end

            Screen('DrawingFinished', window);

            %We currently take events from eye movements, keyboard and the
            %mouse; each event type calls up its own list of event checkers.
            %This may be generalised to a variety of event sources.

            %Now start in on event checking.
            
            %start with an estimate of when your frame will hit the screen,
            %and what refresh...
            s = struct('next', VBL + 2*flipInterval, 'refresh', refresh);

            %read from all input devices and process event handlers
            for i = 1:numel(input)
                s = input(i).input(s);
            end
            
            for i = 1:numel(triggers)
                s = triggers(i).check(s);
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
