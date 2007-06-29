function this = CircleInterpolationTrial(varargin)
%TODO re-cast this in terms of number of refreshes seen.

%A circular motion with multiple spokes is generated; it is played
%for a short time and then a comaprison bar is flashed.

radius = 10;
dx = 0.75;
dt = 0.15;

patch = CauchyPatch...
    ( 'velocity', dx/dt ...
    , 'size', [0.5 0.75 0.1]...
    );

% The onsets of the objects (must be ascending and within a
% window of dt)
onsets = 0;
phases = 0;

n = 3;

barGap = 1.5; %gap between inside and outside bars
barLength = 5; %length of inside and outside bars
barWidth = 0.1; %width of bars
barDuration = 1/30; %duration of bar presentation

barPhase = dx/radius*2;
barOnset = dt*2;

this = autoobject(varargin{:});

%------ methods ------

    function result = run(params)
        frameInterval = params.cal.interval;
        
        result = struct();

        function stopExperiment(s)
            main.stop();
            result.abort = 1;
        end


        motion = CircularMotionProcess ...
            ( 'radius', radius ...
            , 'n', n ...
            , 't', onsets ...
            , 'phase', phases ...
            , 'dt', dt ...
            , 'dphase', dx / radius ...
            , 'angle', 90 + phases * 180 / pi ...
            , 'color', [0.5 0.5 0.5] ...
            );

        sprites = SpritePlayer(patch, motion);

        insideBarRadius = radius - barGap/2 - barLength/2;
        outsideBarRadius = radius + barGap/2 + barLength/2;

        insideBar = FilledBar...
            ( 'x', insideBarRadius * cos(barPhase), 'y', -insideBarRadius * sin(barPhase)...
            , 'length', barLength, 'width', barWidth, 'angle', barPhase * 180/pi...
            , 'color', params.whiteIndex);

        outsideBar = FilledBar...
            ( 'x', outsideBarRadius * cos(barPhase), 'y', -outsideBarRadius * sin(barPhase)...
            , 'length', barLength, 'width', barWidth, 'angle', barPhase * 180/pi...
            , 'color', params.whiteIndex);

        barOffset = 0;
        
        comparisonBar = FilledBar ...
            ( 'x', radius * cos(barPhase), 'y', -radius * sin(barPhase) ...
            , 'length', barGap - 0.5, 'width', barWidth ...
            , 'angle', barPhase * 180 / pi ...
            );

        fixation = FilledDisk([0 0], 0.1, params.blackIndex, 'visible', 1);

        startTrigger = UpdateTrigger(@start);
        timer = RefreshTrigger();

        keydown = KeyDown();
        keydown.set(@stopExperiment, 'q');
        
        mousedown = MouseDown();
        mousemove = MouseMove();
        
        main = mainLoop ...
            ( {sprites, fixation, insideBar, outsideBar, comparisonBar} ...
            , {startTrigger, timer} ...
            , 'keyboard', keydown ...
            , 'mouse', {mousedown, mousemove} ...
            );

        main.go(params);

        %event handler functions
        
        function start(s)
            startTrigger.unset();
            timer.set(s.refresh + 1/frameInterval, @showMotion);
        end

        function showMotion(s)
            sprites.setVisible(1, s.next); %onset recorded in the trigger.
            timer.set(s.refresh + round(barOnset/frameInterval), @showBars);
        end

        function showBars(s)
            insideBar.setVisible(1);
            outsideBar.setVisible(1);
            timer.set(s.triggerRefresh + round(barDuration/frameInterval), @hideBars);
        end

        function hideBars(s)
            insideBar.setVisible(0);
            outsideBar.setVisible(0);

            timer.set(s.triggerRefresh + 1/frameInterval, @showComparison);
        end
        
        function showComparison(s)
            sprites.setVisible(0);
            insideBar.setVisible(1);
            outsideBar.setVisible(1);
            comparisonBar.setVisible(1);
            timer.unset();
            mousemove.set(@moveComparisonBar);
            mousedown.set(@accept);
        end
        
        function moveComparisonBar(s)
            %use the y-axis for now...
            comparisonBar.setX();
            comparisonBar.setY();
            comparisonBar.setAngle()
        end
        
        function accept(s)
            comparisonBar.setVisible(0);
            insideBar.setVisible(0);
            outsideBar.setVisible(0);
            fixation.setVisible(0);
            
            %TODO set the result
            
            %push the blank frame to the screen, then stop
            timer.set(s.refresh+1, main.stop);
        end
    end
end
