function this = DoubleSaccadeTrial(varargin)
    %Adapted from SpriteProcessTest.m
    %There are two targets, governed by two motion processes.
    %After a short fixation at the dot, the motion processes begin,
    %followed by jump of the fixation point towards one of the targets.
    %The targets are extinguished at the onset of the saccade, and come
    %back when the eye enters the vicinity of the target.
    
    dx = .75;
    dt = 0.15;
    patch = CauchyPatch...
        ( 'velocity', dx/dt ...
        , 'size', [0.5 0.75 0.1]...
        );

    onset = 0.5; %time to onset of stimulus after fixation is established
    cue = 1.0; %default value gives 1 second of tracking

    %the origin
    %basic randomization (do this in the trial generator for reals.)
    %basic: the positions at cue time will not be less than 90 degrees
    %apart on the circle.

    dir1_ = rand() * 360;
    dir2_ = dir1_ + 180 + (rand()-0.5)*180;
    radius_ = 10;
    
    angle1 = rand()*360;
    angle2 = rand()*360;
    
    origin1 = [cos(dir1_ * pi/180) -sin(dir1_ *pi/180)] * radius_;
    origin2 = [cos(dir2_ * pi/180) -sin(dir2_ *pi/180)] * radius_;
    origin1 = origin1 - (dx/dt) * (onset-cue) * [cos(angle1*pi/180) -sin(angle1*pi/180)];
    origin2 = origin2 - (dx/dt) * (onset-cue) * [cos(angle2*pi/180) -sin(angle2*pi/180)];
        
    complementary1 = round(rand);
    complementary2 = round(rand);

    %basic randomization of origin
    
    %eye tracking parameters
    fixationSettleTime = 0.050;
    fixationAverageTime = 0.1;
    coarseFixationWindow = 2;
    fineFixationWindow = 0.5;
    targetWindow = 3;
    cueJump = 1;
    cueJumpDuration = 0.05;
    saccadeMaxLatency = 0.3;
    saccadeMaxTransit1 = 0.3;
    saccadeMaxTransit2 = 0.4;
    saccadeTrackDuration = 0.3;
    
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        interval = params.cal.interval;

        motion1 = SimpleMotionProcess ...
            ( 'origin', origin1 ...
            , 'dx', [dx * cos(angle1/180*pi), -dx*sin(angle1/180*pi)] ...
            , 'angle', angle1 + (180 * ~complementary1) ...
            , 'dt', dt ...
            , 'onset', onset ...
            );

        motion2 = SimpleMotionProcess ...
            ( 'origin', origin2 ...
            , 'dx', [dx * cos(angle2/180*pi), -dx*sin(angle2/180*pi)] ...
            , 'angle', angle2 + (180 * ~complementary2) ...
            , 'dt', dt ...
            , 'onset', onset ...
            );

        sprites1 = SpritePlayer(patch, motion1);
        sprites2 = SpritePlayer(patch, motion2);

        fixationPoint = FilledDisk([0 0], 0.1, params.blackIndex, 'visible', 1);

        %that's it for graphical elements. Now for the event structure:

        in = InsideTrigger();
        out= OutsideTrigger();
        timer1 = RefreshTrigger();
        timer2 = RefreshTrigger();

        fixationSamples = 0;
        fixationTotal = [0 0];

        averagedFixation = [0 0];

        function awaitFixation(s)
            fixationSamples = 0;
            fixationTotal = [0 0];
            in.set(fixationPoint.bounds, coarseFixationWindow, [0 0], @settleFixation);
            out.unset();
            timer1.unset();
            timer2.unset();
        end

        function settleFixation(s)
            
            in.unset();
            out.set(fixationPoint.bounds, coarseFixationWindow, [0 0], @awaitFixation);
            timer1.set(@averageFixation ...
                , s.refresh + round(fixationSettleTime / interval)
                , 1);
            timer2.set(@beginTrial ...
                , s.refresh + round((fixationSettleTime + fixationAverageTime) / interval) );
        end

        function averageFixation(s)
            if (~isnan(s.x))
                fixationTotal = fixationTotal + [s.x s.y];
                fixationSamples = fixationSamples + 1;
            end
        end

        function beginTrial(s)
            averagedFixation = fixationTotal / fixationSamples;

            sprites1.setVisible(1);
            sprites2.setVisible(1); %onset is counted from now...

            out.set(fixationPoint.bounds, fineFixationWindow, averagedFixation, @failed);
            timer1.set(@cueSaccade, s.refresh + round(cue / interval));
            timer2.unset();
        end

        function cueSaccade(s)
            where = sprites1.bounds();
            where = (where([1 2]) + where([3 4]))/2;
            
            %normalize the jump in fixation point
            l = fixationPoint.getLoc();
            jump = (where - l);
            jump = jump / norm(jump) * cueJump;
            fixationPoint.setLoc(l + jump);
            out.set(fixationPoint.bounds, fineFixationWindow, averagedFixation - jump, @saccadeTransit1, 0);
            timer1.set(@failed, s.refresh + round(saccadeMaxLatency / interval) );
            timer2.set(@fixationOff, s.refresh + round(cueJumpDuration / interval) );
        end

        function fixationOff(s)
            fixationPoint.setVisible(0);
            timer2.unset();
        end

        function saccadeTransit1(s)
            %hide the visual stimuli, await the destination
            sprites1.setDrawn(0);
            sprites2.setDrawn(0);
            in.set(sprites1.bounds, targetWindow, [0 0], @saccadeTransit2);
            out.unset();
            timer1.set(@failed, s.refresh + round(saccadeMaxTransit1/interval));
        end

        function saccadeTransit2(s)
            sprites1.setDrawn(1);
            timer1.set(@failed, s.refresh + round(saccadeMaxTransit2/interval));
            in.set(sprites2.bounds, targetWindow, [0 0], @saccadeTransitDone);
        end
        
        function saccadeTransitDone(s)
            sprites2.setDrawn(1);
            in.unset();
            timer1.set(@done, s.refresh + round(saccadeTrackDuration/interval));
            out.set(sprites2.bounds, targetWindow, [0 0], @failed, 1);
        end
           
        function failed(s)
            %FAIL
            stop(s);
        end

        function done(s)
            %WIN
            result.success = 1;
            stop(s);
        end

        function abort(s) %these are so you have different things in the log file
            result.abort = 1;
            stop(s);
        end

        function stop(s)
            fixationPoint.setVisible(0)
            sprites1.setDrawn(0);
            sprites2.setDrawn(0);
            timer1.set(main.stop, s.refresh + 1);
            timer2.unset();
            in.unset();
            out.unset();
        end

        if params.diagnostics
            %----- visible state and gaze indicator (development feedback)
            %----
            gaze = FilledDisk([0 0], 0.1, [params.whiteIndex 0 0], 'visible', 1);
            gazeupdate = UpdateTrigger(@(s) gaze.setLoc([s.x s.y]));
            
            outlines = TriggerDrawer();
            outlines.setVisible(1);
            
            main = mainLoop ...
                ( {sprites1, sprites2, fixationPoint, gaze, outlines} ...
                , {in, out, timer1, timer2, gazeupdate} ...
                , 'keyboard', {KeyDown(@abort, 'q')} ...
                );
            outlines.set(main);
        else
            main = mainLoop ...
                ( {sprites1, sprites2, fixationPoint} ...
                , {in, out, timer1, timer2} ...
                , 'keyboard', {KeyDown(@abort, 'q')} ...
                );
        end

        result = struct('success', 0);
        
        awaitFixation();

        params = main.go(params);
    end

end