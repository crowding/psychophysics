function JumpyRectangle
% a simple gaze-contingent graphics demo. Demonstrates the use of triggers.

require(@setupEyelinkExperiment, @runDemo);
    function runDemo(screenDetails)
    
        canvas = Drawing(screenDetails.window, screenDetails.cal);
    
        back = Background(screenDetails.gray);
        rect = FilledRect([100 100 200 200], screenDetails.black);
        disk = FilledDisk(500, 500, 25, screenDetails.white);
                
        back.setVisible(1);
        rect.setVisible(1);
        disk.setVisible(1);
        
        canvas.add(back);
        canvas.add(rect);
        canvas.add(disk);
        
        events = eyeEvents(screenDetails.el);
        go = 1;

        events.add(InsideTrigger(rect, @moveRect));
        events.add(UpdateTrigger(@followDisk));
        events.add(TimeTrigger(GetSecs() + 10, @stop));

        % ----- the main loop, now reduced to 3 lines -----
        
        while(go)
            events.update();
            canvas.draw();
            Screen('Flip', screenDetails.window);
        end

        %----- thet event reaction functions -----

        function stop(x, y, t)
            go = 0;
        end

        function r = moveRect(x, y, t)
            %set the rectangle to a random color and shape
            rect.setRect(randomRect(screenDetails.rect));
        end
        
        function r = followDisk(x, y, t)
            %make the disk follow the eye
            disk.setLoc(x, y);
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