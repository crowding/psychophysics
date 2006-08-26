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

    function details = go(details)
        %run the main loop, collecting events, calling triggers, and 
        %redrawing the screen until stop() is called.
        %
        %Initializes the event managers and sets high CPU priority before
        %running.
        details = require(events_.initializer(details), highPriority(), @doGo);
    end

    function details = doGo(details)
        go_ = 1;
        interval = details.cal.interval;
        hitcount = 0;
        skipcount = 0;
        lastVBL = Screen('Flip', details.window);
        
        while(go_)
            %take a sample from the eyetracker and react to it
            events_.update(lastVBL + interval);
            
            if ~go_ %the update may cause us to exit;
                break;
            end

            %check for an escape key
            [keyIsDown, secs, keyCodes] = KbCheck();
            if keyIsDown && keyCodes(KbName('ESCAPE'))
                error('mainLoop:userExit', 'user escaped from main loop.');
            end
            
            canvas_.draw();

            [VBL] = Screen('Flip', details.window, 0, 0);
            hitcount = hitcount + 1;
            
            %count the number of frames advanced and do the
            %appropriate number of canvas.update()s
            if lastVBL > 0
                frames = round((VBL - lastVBL) / interval);
                skipcount = skipcount + frames - 1;
                
                %if frames > 1
                %    noop; 
                %end
                
                if frames > 60
                    error('mainLoop:drawingStuck', ...
                        'got stuck doing frame updates...');
                end
                for i = 1:frames
                    %may accumulate error if
                    %interval differs from the actual interval...
                    %but we're screwed in that case.
                    canvas_.update();
                end
            else
                %one update for the first time
                canvas_.update();
            end
            lastVBL = VBL;
        end
        disp(sprintf('hit %d frames, skipped %d', hitcount, skipcount));
    end

    function stop(x, y, t, next)
        %Stops the main loop. Takes arguments compatible with beign called
        %from a trigger.
        %
        %See also mainLoop>go.
        go_ = 0;
    end

end
