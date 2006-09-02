function [this, canvas_, events_] = mainLoop(details_)

this = public(@canvas, @mouse, @go, @stop);

%-----instance variables-----
canvas_ = Drawing(details_);
events_ = EyeEvents();

go_ = 0;

    function c = canvas
        c = canvas_;
    end

    function m = eye
        m = mouse_;
    end

    function go()
        %run the main loop, collecting events, calling triggers, and 
        %redrawing the screen until stop() is called.
        %
        %Initializes the event managers and sets high CPU priority before
        %running.
        require(events_.initializer(details_), listenChars(), highPriority(), @doGo);
    end

    function details = doGo(details)
        go_ = 1;
        interval = details.cal.interval;
        hitcount = 0;
        skipcount = 0;
        lastVBL = Screen('Flip', details.window);
        
        %for better speed in the loop, eschew struct access
        pushEvents = events_.update;
        log = details.log;
        window = details.window;
        drawScreen = canvas_.draw;
        stepFrame = canvas_.update;
        
        ListenChar();
        
        %the main loop
        while(1)
            %take a sample from the eyetracker and react to it
            pushEvents(lastVBL + interval); %was  27.73    3469   
            
            if ~go_
                break;
            end

            %check for the quit key
            if CharAvail() && lower(GetChar()) == 'q' %was  6.31    3459  
                error('mainLoop:userCanceled', 'user escaped from main loop.');
            end
            
            drawScreen();

            [VBL] = Screen('Flip', window, 0, 0); %was 20.00    3458   
            hitcount = hitcount + 1;
            
            %count the number of frames advanced and do the
            %appropriate number of canvas.update()s
            frames = round((VBL - lastVBL) / interval);
            skipcount = skipcount + frames - 1;

            if frames > 1
                log('FRAME_SKIP %d %f %f', frames-1, lastVBL, VBL); %was  0.57     600  
            end

            if frames > 60
                error('mainLoop:drawingStuck', ...
                    'got stuck doing frame updates...');
            end
            
            for i = 1:frames
                %may accumulate error if
                %interval differs from the actual interval...
                %but we're screwed in that case.
                stepFrame(); %was   4.47    4060   
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

end
