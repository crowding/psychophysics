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
barLength = 1; %length of inside and outside bars
barWidth = 0.1; %width of bars
barDuration = 1/30; %duration of bar presentation

barPhase = dx/radius*2;
barOnset = dt*2;

simulate = 0;

this = autoobject(varargin{:});

%------ methods ------

    function result = run(params)
        frameInterval = params.cal.interval;

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

        fixation = FilledDisk([0 0], 0.1, params.blackIndex, 'visible', 1);

        startTrigger = UpdateTrigger(@start);
        timer = RefreshTrigger();

        onset = 0;

        main = mainLoop ...
            ( {sprites, fixation, insideBar, outsideBar} ...
            , {startTrigger, timer} ...
            );

        params = main.go(params);

        %event handler functions
        function start(s)
            startTrigger.unset();
            timer.set(s.refresh + 1/frameInterval, @showMotion);
        end

        function showMotion(s)
            sprites.setVisible(1, s.next); %will be recorded as a trigger
            
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

            timer.set(s.triggerRefresh + (dt * (n + 2))/frameInterval, @hideMotion);
        end

        function hideMotion(s)
            sprites.setVisible(0);
            fixation.setVisible(0);
            %now wait for a keystroke...
            timer.set(s.refresh + 1/frameInterval, main.stop);
        end

        %the result will eventually give something of the subject's
        %response
    end
end
