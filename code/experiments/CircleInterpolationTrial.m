function this = CircleInterpolationTrial(varargin)

%A circular motion with multiple spokes is generated; it is played
%for a short time and then a comaprison bar is flashed.

%eye tracking parameters
fixationSettleTime = 0.35;
fixationAverageTime = 0.1;
coarseFixationWindow = 5;
fineFixationWindow = 3; %why must it be so large?
nFixationSamples = 10;

%basic motion parameters (these are passed to circularMotion itself)
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

n = 3; %the number of flashes for each object

barGap = 1.5; %gap between inside and outside bars
barLength = 3; %length of inside and outside bars
barWidth = 0.1; %width of bars
barDuration = 1/30; %duration of bar presentation

barPhase = dx/radius*2;
barOnset = dt*2;

comparisonBarDelay = 0.5;

failureTones = repmat([500 0.1 0.9 0 0.1 0], 1, 3);
    
this = autoobject(varargin{:});

failureSound_ = tones(failureTones);


%------ methods ------
    function setFailureTones(v)
        failureSound_ = tones(failureTones);
    end

    function [params, result] = run(params)
        
        interval = params.cal.interval;
        
        result = struct();

        function stopExperiment(s)
            main.stop();
            result.abort = 1;
            result.responseDisplacement = NaN;
            result.accepted = 0;
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
            , 'length', barGap - 2*barWidth, 'width', barWidth ...
            , 'angle', barPhase * 180 / pi ...
            , 'color', params.whiteIndex ...
            );

        fixationPoint = FilledDisk([0 0], 0.1, params.blackIndex, 'visible', 1);

        in = InsideTrigger();
        out = OutsideTrigger();
        timer = RefreshTrigger();
        
        keydown = KeyDown();
        keydown.set(@stopExperiment, 'q');
        
        mousedown = MouseDown();
        mousemove = MouseMove();
        
        in = InsideTrigger();
        out = OutsideTrigger();
        
        main = mainLoop ...
            ( {sprites, fixationPoint, insideBar, outsideBar, comparisonBar} ...
            , {in, out, timer} ...
            , 'keyboard', {keydown} ...
            , 'mouse', {mousedown, mousemove} ...
            );

        %event handler functions
        
        %we begin by averaging the fixation.
        fixationSamples = 0;
        fixationTotal = [0 0];
        averagedFixation = [0 0];
        
        function awaitFixation(s)
            fixationPoint.setVisible(1);
            fixationSamples = 0;
            fixationTotal = [0 0];
            in.set(fixationPoint.bounds, coarseFixationWindow, [0 0], @settleFixation);
            out.unset();
            timer.unset();
        end

        function settleFixation(s)
            in.unset();
            out.set(fixationPoint.bounds, coarseFixationWindow, [0 0], @awaitFixation);
            timer.set(@averageFixation ...
                , s.refresh + round(fixationSettleTime / interval) ...
                , 1);
        end

        function averageFixation(s)
            if (~isnan(s.x))
                fixationTotal = fixationTotal + [s.x s.y];
                fixationSamples = fixationSamples + 1;
                if (fixationSamples >= nFixationSamples)
                    timer.set(@start, s.refresh + 1);
                end
                if (s.refresh - s.triggerRefresh)/2 >= nFixationSamples
                    timer.set(@retryFixation, s.refresh+1);
                end
            end
        end
        
        function retryFixation(s)
            timer.unset();
            fixationPoint.setVisible(0);
            out.set(fixationPoint.bounds, coarseFixationWindow, [0 0], @awaitFixation);
        end
        
        function start(s)
            averagedFixation = fixationTotal / fixationSamples;

            timer.set(@showMotion, s.refresh + 1);
            in.unset;
            out.set(fixationPoint.bounds, fineFixationWindow, [0 0], @failed);
        end

        function showMotion(s)
            sprites.setVisible(1, s.next); %onset recorded in the trigger.
            timer.set(@showBars, s.refresh + round(barOnset/interval));
        end

        function showBars(s)
            insideBar.setVisible(1);
            outsideBar.setVisible(1);
            timer.set(@hideBars, s.triggerRefresh + round(barDuration/interval));
        end

        function hideBars(s)
            insideBar.setVisible(0);
            outsideBar.setVisible(0);

            timer.set(@showComparison, s.triggerRefresh + round(comparisonBarDelay/interval));
        end
        
        function showComparison(s)
            insideBar.setVisible(1);
            outsideBar.setVisible(1);
            comparisonBar.setVisible(1);
            timer.unset();
            out.unset();
            mousemove.set(@moveComparisonBar);
            mousedown.set(@accept);
            keydown.set(@decline, 'space');
        end
        
        function moveComparisonBar(s)
            %Project the mouse movement onto the vector tangent to the
            %circle and move according to that distance.
            thisPhase = barPhase + barOffset/radius;
            move = - s.movex_deg * sin(thisPhase) - s.movey_deg * cos(thisPhase);
            barOffset = barOffset + move;
            
            thisPhase = barPhase + barOffset/radius;
            
            comparisonBar.setX(radius * cos(thisPhase));
            comparisonBar.setY(-radius * sin(thisPhase));
            comparisonBar.setAngle(thisPhase * 180/pi);
        end
        
        function accept(s)
            comparisonBar.setVisible(0);
            insideBar.setVisible(0);
            outsideBar.setVisible(0);
            fixationPoint.setVisible(0);
          
            mousemove.unset();
            mousedown.unset();
            keydown.unset();
            
            result.responseDisplacement = barOffset;
            result.accepted = 1;
            
            %push the blank frame to the screen, then stop
            timer.set(main.stop, s.refresh+1);
        end
        
        function decline(s)
            comparisonBar.setVisible(0);
            insideBar.setVisible(0);
            outsideBar.setVisible(0);
            fixationPoint.setVisible(0);
            
            mousemove.unset();
            mousedown.unset();
            result.responseDisplacement = barOffset;
            result.accepted = 0;
            
            %push the blank frame to the screen, then stop
            timer.set(main.stop, s.refresh+2);
        end
        
        function failed(s)
            comparisonBar.setVisible(0);
            insideBar.setVisible(0);
            outsideBar.setVisible(0);
            fixationPoint.setVisible(0);

            mousemove.unset();
            mousedown.unset();
            result.barOffset = NaN;
            result.accepted = 0;
            out.unset();
            in.unset();
            timer.set(main.stop, s.refresh+2);
            play(failureSound_());
        end
        
        awaitFixation();
        params = main.go(params);
    end
end