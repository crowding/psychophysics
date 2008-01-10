function JumpyRectangle(varargin)

defaults = struct ...
    ( 'edfname', '' ...
    , 'input', struct ...
        ( 'mouse', MouseInput()...
        , 'velocity', EyeVelocityFilter()...
        )...
    );

params = namedargs(localExperimentParams(), defaults, varargin{:});

% a simple gaze-contingent graphics demo. Demonstrates the use of triggers.
% Also uses a velocity filter...

%setupEyelinkExperiment does everything up to preparing the trial;
%mainLoop.go does everything after.

inputs = interface(struct('init', {}), struct2cell(params.input));

require(getScreen(params), inputs.init, @runDemo);
    function runDemo(details)
        indegrees = transformToDegrees(details.cal);

        patch = MoviePlayer(CauchyPatch);
        rect = FilledRect([-2 -2 2 2], details.blackIndex);
        disk1 = FilledDisk([-2 2], 0.5, details.whiteIndex);
        disk2 = FilledDisk([-2 2], 0.25, [details.whiteIndex details.whiteIndex details.blackIndex]);
        disk3 = FilledDisk([-2 2], 0.25, [details.whiteIndex details.blackIndex details.whiteIndex]);
        disk4 = FilledDisk([-2 2], 0.25, [details.blackIndex details.whiteIndex details.whiteIndex]);
        text = Text([-5 -5], 'hello world!', [details.whiteIndex 0 0]);
        triggers = TriggerDrawer();
        
        moveTrigger = InsideTrigger(rect.bounds, 0, [0 0], @moveRect);
        followTrigger = UpdateTrigger(@followDisk);
        startTrigger = UpdateTrigger(@start);
        playTrigger = TimeTrigger();
        stopTrigger = TimeTrigger();
        abortTrigger = MouseDown();
        if isfield(details.input.eyes, 'reward')
            reward = details.input.eyes.reward;
        else
            reward = @noop;
        end
        
        rect.setVisible(1);
        disk1.setVisible(1);
        disk2.setVisible(1);
        disk3.setVisible(1);
        disk4.setVisible(1);
        text.setVisible(1);
        triggers.setVisible(1);
        
        % ----- the main loop. -----
        main = mainLoop ...
            ( 'input', {params.input.eyes, params.input.mouse, params.input.velocity}...
            , 'graphics', {rect, disk1, disk2, disk3, disk4, text, patch} ...
            , 'triggers', {moveTrigger, startTrigger, playTrigger, stopTrigger, followTrigger, abortTrigger} ...
            );
        %   , 'keyboard', {keyTrigger} ...
            
        abortTrigger.set(main.stop, 1);
        
        triggers.set(main);

        main.go(details);

        %----- thet event handling functions -----

        function start(s)
            playTrigger.set(s.next + 5, @play);
            stopTrigger.set(s.next + 100, main.stop);
            startTrigger.unset();
        end
        
        function play(s)
            patch.setVisible(1);
            playTrigger.set(s.triggerTime + 5, @play); %trigger every five seconds
        end

        function s = moveRect(s)
            %set the rectangle to a random color and shape
            reward(s.refresh, 10);
            rect.setRect(randomRect(indegrees(details.rect)));
        end

        function s = followDisk(s)
            %make the disk follow the mouse
            disk1.setLoc([s.mousex_deg s.mousey_deg]);
            disk2.setLoc([s.x s.y]);
            if ~isempty(s.eyeFx)
                disk3.setLoc([s.eyeFx(end) s.eyeFy(end)]);
                disk4.setLoc([s.eyeFx(end)+s.eyeVx(end)*0.02 s.eyeFy(end)+s.eyeVy(end)*0.02]);
            end            
            text.setText(sprintf('%0.2f, %0.2f | %0.2f, %0.2f | %0.3f, %0.3f', s.mousex_deg, s.mousey_deg, s.x, s.y, s.mouset, GetSecs()));
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
