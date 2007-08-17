function FlipTimingTest
    %test several timing loops withthe aim of maximizing the amount of crap
    %you can get done in the loop, while preserving the ability to hit
    %every frame and detect skips.

    require(getScreen('requireCalibration', 0), highPriority(), @runTest);
    function runTest(params)
        delay = linspace(0, params.cal.interval*1.05, 500);

        info  = Screen('GetWindowInfo', params.window);
        [interval n stddev] = Screen('GetFlipInterval', params.window);

        i = 0;
        nRects = 20;
        
        printf('Loop 0, regular:    %f', staircase(@loop0,             0, 0.001, 3, 1, 10));
        printf('Loop 0, occasional: %f', staircase(occasional(@loop0), 0, 0.001, 3, 1, 10));
        printf('Loop 1, regular:    %f', staircase(@loop1,             0, 0.001, 3, 1, 10));
        printf('Loop 1, occasional: %f', staircase(occasional(@loop1), 0, 0.001, 3, 1, 10));
        printf('Loop 2, regular:    %f', staircase(@loop2,             0, 0.001, 3, 1, 10));
        printf('Loop 2, occasional: %f', staircase(occasional(@loop2), 0, 0.001, 3, 1, 10));
        printf('Loop 3, regular:    %f', staircase(@loop3,             0, 0.001, 3, 1, 10));
        printf('Loop 3, occasional: %f', staircase(occasional(@loop3), 0, 0.001, 3, 1, 10));
        
        function [value, skips, values] = staircase(fn, value, step, nup, ndown, nreversals)
            %Given a timing loop 'fn' that draws something to the screen,
            %executes a flip, incorporates some processing delay,
            %and determines whether the timing deadlines
            %are met, this function executes a staircase to find out how
            %much processing delay you can have in the function.
            %fn -- a function that executes the timing loop once.
            %value -- initial value of the delay.
            %step -- initial step size
            %nup -- number of loops executed without skipping before
            %stepping up.
            %ndown -- number of skipping loops executed before stepping
            %down.
            %nreversals -- number of reversals to look for.
            
            value = 0;
            step = 0.001;
            direction = 1;
            reversals = 0;
            upCount = 0;
            downCount = 0;
            
            [skips, values] = deal(zeros(1000, 1));
            count = 0;
            
            lastVBL = Screen('Flip', params.window);
            while(reversals < nreversals && count < 1000)
                count = count + 1;
                [skips(count), lastVBL] = fn(value, lastVBL);
                values(count) = value;
                
                if (skips(count) > 0) %skipped, need to go down.
                    upCount = 0;
                    downCount = downCount + 1;
                    if downCount >= ndown
                        if direction > 0
                            reversals = reversals + 1;
                            step = step/2;
                            direction = -1;
                        end
                        value = value + step * direction;
                    end
                    
                else %no skip, need to go up
                    downCount = 0;
                    upCount = upCount + 1;
                    if upCount >= nup
                        if direction < 0
                            reversals = reversals + 1;
                            step = step/2;
                            direction = 1;
                        end
                        value = value + step*direction;
                    end
                    
                end
            end
            
            skips(count+1:end) = [];
            values(count+1:end) = [];
            figure(1);
            subplot(2, 1, 1);
            plot(1:count, skips);
            subplot(2, 1, 2);
            plot(1:count, values, 'b.');
            drawnow;
            
            if (count >= 1000)
                noop();
            end
        end
        
        function fn = occasional(loop)
            %Tests tolerance for occasional large delays, by executing the
            %delay only one out of 6 frames.
            fn = @f;
            function [skipped, VBL] = f(delay, lastVBL)
                skipped = 0;
                for i = 1:5
                    [skip, lastVBL] = loop(0, lastVBL);
                    skipped = skipped + skip;
                end
                [skip, VBL] = loop(delay, lastVBL);
                skipped = skipped + skip;
            end
        end
        
        function [skipped, VBL] = loop0(delay, lastVBL)
                %the 'low latency' timing loop. Executes delay before
                %drawing and calling flip.
                WaitSecs(delay); %here is where you would put your input checking etc.
                randRects(nRects, params.window, params.rect);
                VBL = Screen('Flip', params.window, [], [], 0);
                skipped = round((VBL - lastVBL) / interval) - 1;
        end
        
        function [skipped, VBL] = loop1(delay, lastVBL)
                %the 'standard' timing loop. Executes delay after drawing
                %and calling DrawingFinished, then executes flip.
                randRects(nRects, params.window, params.rect);
                Screen('DrawingFinished', params.window);
                WaitSecs(delay); %here is where you would put your input checking etc.
                VBL = Screen('Flip', params.window, [], [], 0);
                skipped = round((VBL - lastVBL) / interval) - 1;
        end

        function [skipped, VBL] = loop2(delay, lastVBL)
            %experimental loop 1. Executed delay after drawing and calling
            %DrawingFinished, then calls Flip returning immediately,
            %estimating frame skips from the beam position after flip.
            
            randRects(nRects, params.window, params.rect);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', params.window, [], [], 1);
            Beampos = Screen('GetWindowInfo', params.window, 1);
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            skipped = round((VBL - lastVBL) / interval) - 1;
        end
        
        function [skipped, VBL] = loop3(delay, lastVBL)
            %experimental loop 2. draws, flips, and returns immediately, 
            %then does the delay.
            
            randRects(nRects, params.window, params.rect);
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', params.window, [], [], 1);
            Beampos = Screen('GetWindowInfo', params.window, 1);
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            skipped = round((VBL - lastVBL) / interval) - 1;

            WaitSecs(delay); %here is where you would put your input checking etc.
        end
        
        function [skipped, VBL] = loop4(delay, lastVBL)
            %experimental loop 4. Draws a number of rectangles for a longer
            %drawing period...
            
            randRects(nRects, params.window, params.rect);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', params.window, [], [], 1);
            Beampos = Screen('GetWindowInfo', params.window, 1);
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            skipped = round((VBL - lastVBL) / interval) - 1;
        end

        function randRects(n, window, bounds)
            Screen('FillRect', params.window, mod(i, 2)*255);
            for j = 1:n
                Screen('FillRect', params.window, rand() * 255, randomRect(bounds));
            end
            i = i + 1;
        end
        
        function r = randomRect(bounds)
            origin = bounds([1 2]);
            size = bounds([3 4]) - origin;
            r = sort(rand(2,2) .* [size;size] + [origin;origin]);
            r = r([1 3 2 4]);
        end
        
    end

        %{
        figure(1);
        [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = test1(delay);
        subplot(3, 1, 1);
        plot(1:500, VBLTimestamp, 'b-', 1:500, StimulusOnsetTime, 'g-', 1:500, FlipTimestamp, 'r-');
        subplot(3, 1, 2);
        plot(1:500, Missed, 'b-', 1:500, Beampos, 'g-');
        subplot(3, 1, 3);
        plot(1:499, diff(VBLTimestamp), 'b-', 1:499, diff(StimulusOnsetTime), 'g-', 1:499, diff(FlipTimestamp), 'r-');
        
        Screen('GetWindowInfo', params.window)
        
        figure(2);
        [FlipTimestamp, Beampos, EstimatedVBL] = test2(delay);
        subplot(3, 1, 1);
        plot(1:500, FlipTimestamp, 'r-', 1:500, EstimatedVBL, 'g-');
        subplot(3, 1, 2);
        plot(1:500, Beampos, 'g-');
        subplot(3, 1, 3);
        plot(1:499, diff(FlipTimestamp), 'b-', 1:499, diff(EstimatedVBL), 'g-');
        
        Screen('GetWindowInfo', params.window);

        function [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = test1(delay)
            [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos] = deal(zeros(size(delay)));
            for i = 1:numel(delay)
                Screen('FillRect', params.window, mod(i, 2)*255);
                Screen('DrawingFinished', params.window);
                WaitSecs(delay(i));
                [VBLTimestamp(i), StimulusOnsetTime(i), FlipTimestamp(i), Missed(i), Beampos(i)]...
                    = Screen('Flip', params.window, [], [], 0);
            end
        end

        function [FlipTimestamp, Beampos, EstimatedVBL] = test2(delay)
            [FlipTimestamp, Beampos, EstimatedVBL] = deal(zeros(size(delay)));
            for i = 1:numel(delay)
                Screen('FillRect', params.window, mod(i, 2)*255);
                Screen('DrawingFinished', params.window);
                WaitSecs(delay(i));
                [tmp, tmp, FlipTimestamp(i)]...
                    = Screen('Flip', params.window, [], [], 1);
                Beampos(i) = Screen('GetWindowInfo', params.window, 1);
                %this can produce some false negatives for frame
                %skipping, maybe?
                EstimatedVBL(i) = FlipTimestamp(i) + (info.VBLStartline - Beampos(i))/info.VBLEndline*interval;
            end
        end
        
        %}
end