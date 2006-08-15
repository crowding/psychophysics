function JumpyRectangle
% a simple gaze-contingent graphics demo. Demonstrates the use of triggers.

require(@setupEyelinkExperiment, @runDemo);
    function runDemo(screenDetails)
    
        canvas = Drawing(screenDetails.cal, screenDetails.window);
    
        cal = screenDetails.cal;
        
        indegrees = transformToDegrees(screenDetails.cal);
        
        back = Background(screenDetails.gray);
        patch = MoviePlayer(CauchyPatch);
        rect = FilledRect([-2 -2 2 2], screenDetails.black);
        disk = FilledDisk([-2 2], 0.5, screenDetails.white);

        canvas.add(back);
        canvas.add(rect);
        canvas.add(disk);
        canvas.add(patch);

        back.setVisible(1);
        rect.setVisible(1);
        disk.setVisible(1);
        
        events = EyeEvents(cal, screenDetails.el);
        go = 1;

        playTrigger = TimeTrigger(0, @play);

        % ----- the main loop, now compact -----
        require(highPriority(screenDetails.window), @mainloop)
        function mainloop
            events.add(InsideTrigger(rect, @moveRect));
            events.add(UpdateTrigger(@followDisk));
            events.add(playTrigger);
            events.add(TimeTrigger(GetSecs() + 20, @stop));
            playTrigger.setTime(GetSecs() + 5);
            
            lastVBL = -1;
            interval = screenDetails.cal.interval;
            while(go)
                events.update();
                canvas.draw();
                
                [VBL] = Screen('Flip', screenDetails.window);
                %count the number of frames advanced and do the
                %appropriate number of canvas.update()s
                if lastVBL > 0
                    disp((VBL - lastVBL) / interval);
                    %for i = 1:round((VBL - lastVBL) / interval)
                        %may accumulate error if
                        %interval differs from the actual interval... 
                        %but we're screwed in that case.
                        canvas.update();
                    %end
                else
                    canvas.update();
                end
                lastVBL = VBL;
            end
        end
        
        canvas.clear();

        %----- thet event reaction functions -----

        function play(x, y, t)
            patch.setVisible(1);
            playTrigger.setTime(playTrigger.time() + 5); %trigger every five seconds
        end
        
        function stop(x, y, t)
            beep;
            go = 0;
        end

        function r = moveRect(x, y, t)
            %set the rectangle to a random color and shape
            rect.setRect(randomRect(indegrees(screenDetails.rect)));
        end
        
        function r = followDisk(x, y, t)
            %make the disk follow the eye
            disk.setLoc([x y]);
        end
        
        function r = randomRect(bounds)
            origin = bounds([1 2]);
            size = bounds([3 4]) - origin;
            r = sort(rand(2,2) .* [size;size] + [origin;origin]);
            %r = [minX minY
            %     maxX maxY]; permute
            r = r([1 3 2 4]);
        end
    end
end