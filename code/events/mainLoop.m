function [this, events_] = mainLoop(params_)
%The main loop which controls presentation of a trial. There are three
%output arguments, main, drawing, and events, which used to be separate
%objects in separate files, but were tied together for speed.
%
%The main loop allows you to start and stop.
%
%The drawing has a list of graphics objects, which

%----- constructed objects -----
this = public(@go, @stop, @addGraphic);
events_ = EyeEvents();

%instance variables
go_ = 0; % flags whether the main loop is running

%the list of graphics components, restricted to the interface we use
graphics_ = struct('draw', {}, 'update', {}, 'init', {});

%----- methods -----

    function params = go(varargin)
        params = namedargs(params_, varargin{:});
        %run the main loop, collecting events, calling triggers, and
        %redrawing the screen until stop() is called.
        %
        %Initializes the event managers and sets high CPU priority before
        %running.
        params = require(events_.initializer(params), graphicsInitializer(), ...
            listenChars(), highPriority(params, 'priority', 0), @doGo);
    end

    function params = doGo(params)
        go_ = 1;
        interval = params.cal.interval;
        hitcount = 0;
        skipcount = 0;
        lastVBL = Screen('Flip', params.window);

        %for better speed in the loop, eschew struct access?
        triggers = events_.getTriggers(); %brutally ugly speed hack
        pushEvents = events_.update;
        log = params.log;
        window = params.window;

        %the main loop
        while(1)
            %take a sample from the eyetracker and react to it
            %triggers is passed in manually because, for whatever reason,
            %looking it up from lexical scope inside the function imposes
            %300% overhead.
            pushEvents(triggers, lastVBL + interval);

            if ~go_
                break;
            end

            %check for the quit key
            if CharAvail() && lower(GetChar()) == 'q'
                error('mainLoop:userCanceled', 'user escaped from main loop.');
            end

            %draw all the objects
            for i = graphics_
                i.draw(window);
            end
                    
            [VBL] = Screen('Flip', window, 0, 0); %was 20.00    3458
            hitcount = hitcount + 1;

            %count the number of frames advanced and do the
            %appropriate number of drawing.update()s
            frames = round((VBL - lastVBL) / interval);
            skipcount = skipcount + frames - 1;

            if frames > 1
                log('FRAME_SKIP %d %f %f', frames-1, lastVBL, VBL);
            end

            if frames > 60
                error('mainLoop:drawingStuck', ...
                    'got stuck doing frame updates...');
            end

            for i = 1:frames
                %may accumulate error if
                %interval differs from the actual interval...
                %but we're screwed in that case.

                %step forward the frame on all objects
                for i = graphics_
                    i.update()
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

        graphics_(end+1) = interface(graphics_, drawer);
    end


    function init = graphicsInitializer(varargin)
        %Produces an initializer to be called as we enter the main loop.
        %
        %The initializer prepares all the graphics objects. On completion,
        %the graphics %objects are released.
        %
        %See also require.

        init = currynamedargs(JoinResource(graphics_.init), varargin{:});
    end

end
