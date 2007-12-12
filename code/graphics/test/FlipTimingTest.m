function FlipTimingTest(varargin)
    params = namedargs(varargin{:})
    %test several timing loops withthe aim of maximizing the amount of crap
    %you can get done in the loop, while preserving the ability to hit
    %every frame and detect skips.

    require(getScreen('requireCalibration', 0, params), highPriority(), @runTest);
    function runTest(params)
        delay = linspace(0, params.cal.interval*1.05, 500);

        info  = Screen('GetWindowInfo', params.window);
        [interval n stddev] = Screen('GetFlipInterval', params.window);

        i = 0;
        nRects = 30;
        if info.VideoRefreshFromBeamposition
            loops = {@loop0, @loop1, @loop2, @loop3, @loop4};
        else
            fprintf('No beampos, not running loops 2, 3\n');
            loops = {@loop0, @loop1, @loop4};
        end
        
        for l = loops(:)'
            for condition = {@(x)x, @occasional; '   regular', 'occasional'}
                i = 0; %will be incremented each draw...
                [fn, desc] = condition{:};
                [value, skips, values, totalvbls, vbls] = staircase(fn(l{:}), 0, 0.001, 5, 1, 0.75, 16);
                fprintf('%45s %f, %d skips detected, should detect %d\n', [func2str(l{:}), ', ' desc ':'], value, sum(skips), totalvbls - i - 1);

                figure(1);
                subplot(3, 1, 1);
                plot(1:count, skips);
                subplot(3, 1, 2);
                plot(1:count, values, 'b.');
                subplot(3, 1, 3);
                plot(diff(vbls));
                drawnow;
            end
        end
        
        function [value, skips, values, totalvbls, vbls] = staircase(fn, value, step, nup, ndown, reduction, nreversals)
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
            total = 0;
            
            [skips, values, vbls] = deal(zeros(1000, 1));
            count = 0;
            
            lastVBL = Screen('Flip', params.window);
            %begin with number of VBLs
            info = Screen('GetWindowInfo', params.window);
            beginVBLcount = info.VBLCount;
            
            while(reversals < nreversals && count < 1000)
                count = count + 1;
                [skips(count), vbls(count)] = fn(value, lastVBL, total);
                lastVBL = vbls(count);
                values(count) = value;
                total = total + skips(count);
                
                if (skips(count) > 0) %skipped, need to go down.
                    upCount = 0;
                    downCount = downCount + 1;
                    if downCount >= ndown
                        if direction > 0
                            reversals = reversals + 1;
                            step = step*reduction;
                            direction = -1;
                        end
                        value = max(value + step * direction, 0);
                    end
                    
                elseif (skips(count) == 0) || value < step %no skip, need to go up
                    downCount = 0;
                    upCount = upCount + 1;
                    if upCount >= nup
                        if direction < 0
                            reversals = reversals + 1;
                            step = step*reduction;
                            direction = 1;
                        end
                        value = max(value + step * direction, 0);
                    end
                end
            end
            
            %push a few low-work frames out to get skips out of the
            %system.
            for x = 1:10
                count = count + 1;
                [skips(count), vbls(count)] = fn(0, lastVBL, total);
                lastVBL = vbls(count);
                values(count) = 0;
                total = total + skips(count);
            end
            lastVBL = Screen('Flip', params.window);
            info = Screen('GetWindowInfo', params.window);
            endVBLcount = info.VBLCount;

            skips(count+1:end) = [];
            values(count+1:end) = [];
            vbls(count+1:end) = [];
            
            totalvbls = endVBLcount - beginVBLcount;
        end
        
        function fn = occasional(loop)
            %Tests tolerance for occasional large delays, by executing the
            %delay only one out of 11 frames.
            fn = @f;
            function [skipped, lastVBL] = f(delay, lastVBL, total)
                skipped = 0;
                for x = 1:5
                    [skip, lastVBL] = loop(0, lastVBL, total+skipped);
                    skipped = skipped + skip;
                end
                [skip, lastVBL] = loop(delay, lastVBL, total+skipped);
                skipped = skipped + skip;
                for x = 1:5
                    [skip, lastVBL] = loop(0, lastVBL, total+skipped);
                    skipped = skipped + skip;
                end
            end
        end
        
        function [skipped, VBL] = loop0(delay, lastVBL, total)
            %The 'low latency' timing loop.
            %
            %Do sundry processing, draw, then execute flip.
            %
            %Get VBL/frame skips directly from flip.

            WaitSecs(delay); %here is where you would put your input checking etc.
            randRects(nRects, params.window, params.rect, total);
            VBL = Screen('Flip', params.window, [], [], 0);
            skipped = round((VBL - lastVBL) / interval) - 1;
        end
        
        
        function [skipped, VBL] = loop1(delay, lastVBL, total)
            %'standard' timing loop.
            %
            %Draw, call DrawingFinished, do sundry processsing, then flip.
            %
            %Get frame skips/VBL from Flip directly.
 
            randRects(nRects, params.window, params.rect, total);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            VBL = Screen('Flip', params.window, [], [], 0);
            skipped = round((VBL - lastVBL) / interval) - 1;                
        end

        %so I think I need to use info for all skip diagnostics...
        function [skipped, VBL] = loop2(delay, lastVBL, total)
            %High throughput loop.
            %
            %Draw, call DrawingFinished, do sundry processing, Flip returning immediately.
            %
            %Estimate VBL/frame skips from beampos.
            
            randRects(nRects, params.window, params.rect, total);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', params.window, [], [], 1);
            info = Screen('GetWindowInfo', params.window);
            Beampos = info.Beamposition;
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            
            skipped = round((VBL - lastVBL) / interval) - 1;
            
            %if we hit ahead of schedule, adjust the VBL estimate...
            if skipped < 0
                VBL = VBL - interval*skipped;
                skipped = 0;
            end
            
            if round((VBL-lastVBL)/interval - 1) ~= skipped
                noop();
            end
        end
        
        function [skipped, VBL] = loop3(delay, lastVBL, total)
            %High throughput loop 2.
            %
            %Draw, flip returning immediately, then do sundry processing.
            %
            %Estimate VBL/frame skips form beampos
            
            randRects(nRects, params.window, params.rect, total);
            [tmp, tmp, FlipTimestamp, tmp, Beampos]...
                = Screen('Flip', params.window, [], [], 1);
            Beampos = Screen('GetWindowInfo', params.window, 1);
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            skipped = round((VBL - lastVBL) / interval) - 1;
            
            %if we draw ahead of schedule, adjust the VBL estimate.
            if skipped < 0
                VBL = VBL - interval*skipped;
                skipped = 0;
            end
            
            WaitSecs(delay); %here is where you would put your input checking etc.
        end
        
        function [skipped, VBL] = loop4(delay, lastVBL, total)
            %Alternate high throughput loop for machines without
            %beamposition...
            %
            %Draw, flip returning immediately, then do sundry processing.
            %
            %Estimate VBL/frame skips from lastVBL value in Screen('GetWindowInfo')
            
            randRects(nRects, params.window, params.rect, total);
            
            %schedule the flip for the next VBL...
            [tmp, tmp, flipTime, missed] = Screen('Flip', params.window, lastVBL + interval/10, [], 1);
            info = Screen('GetWindowInfo', params.window);

            %the previous info structure contains the estimated refresh
            %count and VBL time of the last drawn frame...
            
            VBL = info.LastVBLTime;
            
            skipped = round((VBL - lastVBL) / interval); %if targeted VBL has already hit, we've skipped, probably.
            
            
            if skipped <= 0 %if we've scheduled the flips, we shouldn't have to 
                VBL = VBL - interval*skipped + interval; %estimate the VBL time since we haven't really got there yet
                skipped = 0;
            else
                VBL = VBL + interval; %estimate the frame will hit the following VBL. Scheduling will make it so.
            end
            WaitSecs(delay); %here is where you would put your input checking etc.
        end
        
        
        
        function [skipped, VBL] = loop5(delay, lastVBL, total)
            %experimental loop 4. Draws a number of rectangles for a longer
            %drawing period...
            
            randRects(nRects, params.window, params.rect, total);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', params.window, [], [], 1);
            Beampos = Screen('GetWindowInfo', params.window, 1);
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            skipped = round((VBL - lastVBL) / interval) - 1;
        end

        function randRects(n, window, bounds, total)
            Screen('FillRect', window, mod(i, 2)*255);
            for j = 1:n
                Screen('FillRect', window, rand() * 255, randomRect(bounds));
            end
            Screen('TextSize', window, 30);
            Screen('DrawText', window, num2str(total), 0, 0, [255 255 0], [0 0 0]);
            i = i + 1;
        end
        
        function r = randomRect(bounds)
            origin = bounds([1 2]) * 0.75 + bounds([3 4]) * 0.25;
            size = (bounds([3 4]) - bounds([1 2]))*0.5; %leave a border
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