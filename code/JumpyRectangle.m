function r = JumpyRectangle
% a non-interactive graphics demo.

require(@setupEyelinkExperiment, @runDemo);
    function runDemo(screenDetails)
    
        canvas = Drawing(screenDetails.window, screenDetails.cal);
    
        back = Background(screenDetails.gray);
        rect = FilledRect([100 100 200 200], screenDetails.black);
                
        bd = back.drawer();
        bd.setVisible(1); %FIXME: yeah, need inheritance/interfaces here
        rd = rect.drawer();
        rd.setVisible(1); %also support for chaining off of method results, FFS

        canvas.add(bd);
        canvas.add(rd);
        
        events = eyeEvents(screenDetails.el);
        go = 1;

        events.addTrigger(UpdateTrigger(@randomizeRect));
        events.addTrigger(TimeTrigger(getSecs() + 5, @stop));

        % ----- the main loop, now reduced to 3 lines -----
        while(go)
            events.update();
            canvas.draw();
            Screen('Flip', screenDetails.window);
        end

        %-----

        function stop
            go = 0
        end

        function r = randomizeRect
            %set the rectangle to a random color and shape
            screen = screenDetails.rect;
            origin = screen([1 2]);
            size = screen([3 4]) - origin;
            r = sort(rand(2,2) .* [size;size] + [origin;origin]);
            %r = [minX minY
            %     maxX maxY]; permute
            r = r([1 3 2 4]);

            rect.setRect(r);
            rect.setColor(screenDetails.black +...
                rand() * (screenDetails.white - screenDetails.black));
        end
    end
end