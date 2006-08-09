function JumpyRectangle
% a simple gaze-contingent graphics demo. Demonstrates the use of triggers.

require(@setupEyelinkExperiment, @runDemo);
    function runDemo(screenDetails)
    
        canvas = Drawing(screenDetails.cal, screenDetails.window);
    
        cal = screenDetails.cal;
        
        indegrees = transformToDegrees(screenDetails.cal);
        
        back = Background(screenDetails.gray);
        rect = FilledRect([-2 -2 2 2], screenDetails.black);
        disk = FilledDisk([-2 2], 0.5, screenDetails.white);
                
        back.visible(1);
        rect.visible(1);
        disk.visible(1);
        
        canvas.add(back);
        canvas.add(rect);
        canvas.add(disk);
        
        events = eyeEvents(cal, screenDetails.el);
        go = 1;

        events.add(InsideTrigger(rect, @moveRect));
        events.add(UpdateTrigger(@followDisk));
        events.add(TimeTrigger(GetSecs() + 30, @stop));

        % ----- the main loop, now compact -----
        require(highPriority(screenDetails.window), @mainloop)
        function mainloop
            events.add(TimeTrigger(GetSecs() + 30, @stop));
            while(go)
                events.update();
                canvas.draw();
                Screen('Flip', screenDetails.window);
            end
        end

        %----- thet event reaction functions -----

        function stop(x, y, t)
            go = 0;
        end

        function r = moveRect(x, y, t)
            %set the rectangle to a random color and shape
            rect.rect(randomRect(indegrees(screenDetails.rect)));
        end
        
        function r = followDisk(x, y, t)
            %make the disk follow the eye
            disk.loc([x y]);
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