function FlipTimingTest(varargin)
    %This demonstrates and measures several stimulus drawing loops. Each
    %loop test several stimulus drawing loops withthe aim of maximizing the amount of
    %processing you can get done in the loop, while preserving the ability to draw
    %every frame and detect skips.
    %
    %Each test loop draws a stimulus frame .the background alternates between
    %black and white on every frame, which gives a visual indicator of
    %whether the frame skip count (in the upper left) corresponts with a
    %visible flash on the screen. It's kind of a noxious display though.
    
    params = namedOptions(varargin{:});

    require(getScreen('requireCalibration', 0, params), highPriority(), @runTest);

    function runTest(params)
        info  = Screen('GetWindowInfo', params.window);
        [interval n stddev] = Screen('GetFlipInterval', params.window);

        i = 0;
        nRects = 30;
        if info.VideoRefreshFromBeamposition
            loops = {@loop0, @loop1, @loop2, @loop3, @loop4, @loop5, @loop6};
        else
            fprintf('beampos not supported on this hardware, not running loops 2, 3\n');
            loops = {@loop0, @loop1, @loop4, @loop6};
        end
        
        for l = loops(:)'
            %Test each loops for steady or occasional loads.
            for condition = {@(x)x, @occasional; '    steady load', 'occasional load'}
                i = 0; %will be incremented each draw...
                [fn, desc] = condition{:};
                [value, skips, values, totalvbls, vbls] = staircase(fn(l{:}), 0, 0.001, 10, 1, 0.75, 8);
                fprintf('%45s: threshold %f s, %d skips detected, should detect %d\n', [func2str(l{:}), ', ' desc ':'], value, sum(skips), totalvbls - i - 1);

                figure(1);
                subplot(3, 1, 1);
                plot(1:count, skips, 'b.');
                ylabel('frame skips detected');
                subplot(3, 1, 2);
                plot(1:count, values, 'b.');
                ylabel('processing load (s)')
                subplot(3, 1, 3);
                plot(diff(vbls), 'b.');
                ylabel('difference between successive VBLs');
                xlabel('trial number');
                drawnow;
            end
        end
        
        function [value, skips, values, totalvbls, vbls] = staircase(fn, value, step, nup, ndown, reduction, nreversals)
            %Given a timing loop 'fn' that draws something to the screen,
            %executes a flip, incorporates some processing delay,
            %and determines whether the timing deadlines
            %are met, this function executes a staircase to find out how
            %much processing delay is tolerated by fn before producing skips.
            
            %fn -- a function that executes the timing loop once.
            %value -- initial value of the delay.
            %step -- initial step size
            %nup -- number of loops executed without skipping before
            %stepping up.
            %ndown -- number of skipping loops executed before stepping
            %down.
            %nreversals -- number of reversals to look for.
            
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
            %Not much room for additional processing but minimizes the
            %latency from 

            WaitSecs(delay); %here is where you would put your input checking etc.
            randRects(nRects, params.window, params.rect, total);
            VBL = Screen('Flip', params.window, [], [], 0);
            skipped = round((VBL - lastVBL) / interval) - 1;
        end
        
        
        function [skipped, VBL] = loop1(delay, lastVBL, total)
            %'standard' timing loop. The one you probably use.
            %
            %Draw, call DrawingFinished, do sundry processsing, then flip.
            %
            %Detects frame skips / VBLs from Flip directly
 
            randRects(nRects, params.window, params.rect, total);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            VBL = Screen('Flip', params.window, [], [], 0);
            skipped = round((VBL - lastVBL) / interval) - 1;                
        end
        
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
            %Estimate VBL/frame skips form beampos.
            
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
            %Alternate high throughput loop for machines not supporting beamposition.
            %
            %Draw, flip returning immediately, then do sundry processing.
            %
            %Estimate VBL/frame skips from lastVBL value in
            %Screen('GetWindowInfo').
            
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
            %Loop 1, using return/immediately/beampos instead of VBL.
            
            randRects(nRects, params.window, params.rect, total);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            [tmp, tmp, FlipTimestamp]...
                = Screen('Flip', params.window, [], [], 1);
            Beampos = Screen('GetWindowInfo', params.window, 1);
            VBL = FlipTimestamp + (info.VBLStartline - Beampos)/info.VBLEndline*interval;
            skipped = round((VBL - lastVBL) / interval) - 1;
        end
        
        function [skipped, VBL] = loop6(delay, lastVBL, total)
            %Loop 5, using flip timestamps instead of beampos.
            
            randRects(nRects, params.window, params.rect, total);
            Screen('DrawingFinished', params.window);
            WaitSecs(delay); %here is where you would put your input checking etc.
            [tmp, tmp, flipTime, missed] = Screen('Flip', params.window, lastVBL + interval/10, [], 1);
            info = Screen('GetWindowInfo', params.window);
            VBL = info.LastVBLTime;
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

end