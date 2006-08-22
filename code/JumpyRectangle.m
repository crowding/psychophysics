function JumpyRectangle
% a simple gaze-contingent graphics demo. Demonstrates the use of triggers.

require(SetupEyelinkExperiment(struct('edfname', '')), @runDemo);
    function runDemo(details)
        [main, canvas, events] = mainLoop(details);

        indegrees = transformToDegrees(details.cal);

        back = Background(details.gray);
        patch = MoviePlayer(CauchyPatch);
        rect = FilledRect([-2 -2 2 2], details.black);
        disk = FilledDisk([-2 2], 0.5, details.white);
        text = Text([-5 -5], 'hello world!', [0 details.white 0]);

        canvas.add(back);
        canvas.add(patch);
        canvas.add(rect);
        canvas.add(disk);
        canvas.add(text);

        back.setVisible(1);
        rect.setVisible(1);
        disk.setVisible(1);
        text.setVisible(1);

        go = 1;

        playTrigger = TimeTrigger();
        stopTrigger = TimeTrigger();

        events.add(InsideTrigger(rect, @moveRect));
        events.add(UpdateTrigger(@followDisk));
        events.add(playTrigger);
        events.add(stopTrigger);
        playTrigger.set(GetSecs() + 5, @play);
        stopTrigger.set(GetSecs() + 20, main.stop);
        
        % ----- the main loop, now not so compact -----
        require(highPriority(details), RecordEyes(), main.go)

        % ----- clean up -----
        canvas.clear();
        events.clear();

        %----- thet event reaction functions -----

        function play(x, y, t)
            patch.setVisible(1);
            playTrigger.set(t + 5, @play); %trigger every five seconds
        end

        function r = moveRect(x, y, t)
            %set the rectangle to a random color and shape
            rect.setRect(randomRect(indegrees(details.rect)));
        end

        function r = followDisk(x, y, t)
            %make the disk follow the eye
            disk.setLoc([x y]);
            text.setText(sprintf('%0.2f, %0.2f', x, y));
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