function JumpyRectangle(varargin)

defaults = struct ...
    ( 'edfname', '' ...
    );

params = namedargs(defaults, varargin{:});

% a simple gaze-contingent graphics demo. Demonstrates the use of triggers.

%setupEyelinkExperiment does everything up to preparing the trial;
%mainLoop.go does everything after.

require(setupEyelinkExperiment(params), @runDemo);
    function runDemo(details)
        indegrees = transformToDegrees(details.cal);

        patch = MoviePlayer(CauchyPatch);
        rect = FilledRect([-2 -2 2 2], details.blackIndex);
        disk = FilledDisk([-2 2], 0.5, details.whiteIndex);
        text = Text([-5 -5], 'hello world!', [details.whiteIndex 0 0]);
        triggers = TriggerDrawer();
        
        go = 1;

        moveTrigger = InsideTrigger(rect.bounds, 0, [0 0], @moveRect);
        followTrigger = UpdateTrigger(@followDisk);
        startTrigger = UpdateTrigger(@start);
        playTrigger = TimeTrigger();
        stopTrigger = TimeTrigger();
        
        rect.setVisible(1);
        disk.setVisible(1);
        text.setVisible(1);
        triggers.setVisible(1);
        
        % ----- the main loop. -----
        main = mainLoop ...
            ( {rect, disk, text, patch, triggers} ...
            , {moveTrigger, followTrigger, startTrigger, playTrigger, stopTrigger} ...
            );
        
        triggers.set(main);

        main.go(details);
        %----- thet event reaction functions -----

        function start(x, y, t, next)
            playTrigger.set(t + 5, @play);
            stopTrigger.set(t + 20, main.stop);
            startTrigger.unset();
        end
        
        function play(x, y, t, next)
            patch.setVisible(1);
            playTrigger.set(t + 5, @play); %trigger every five seconds
        end

        function r = moveRect(x, y, t, next)
            %set the rectangle to a random color and shape
            rect.setRect(randomRect(indegrees(details.rect)));
        end

        function r = followDisk(x, y, t, next)
            %make the disk follow the eye
            disk.setLoc([x y]);
            text.setText(sprintf('%0.2f, %0.2f\n%0.3f, %0.3f', x, y, t, GetSecs()));
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
