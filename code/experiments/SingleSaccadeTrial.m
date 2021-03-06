function this = SingleSaccadeTrial(varargin)
    %Adapted from SpriteProcessTest.m
    %There are some number of targets distributed roughly around a circle,
    %and going in all directions with random coherences. At some point the
    %fixation point jumps towards one of the objects. The subject must then
    %make a saccade toward that object and 

    persistent defaultpatch_;
    if isempty(defaultpatch_)
        defaultpatch_ = CauchyPatch...
            ( 'velocity', 5 ...
            , 'size', [0.5 0.75 0.1]...
            );
    end
    
    %vvvvvvv randomization
    %private parameters for initial randomization
    
    %------ public parameters initialized with randomization ------
    
    %and their orientations are the same as the angles, or opposite
    cue = 1.0; %default value gives 1 second of tracking
    patch = defaultpatch_;

    dx = [0.749992237028656 -0.342470727089352 -0.721387304278002];
    dy = [-0.00341238871652169 -0.667243434652519 0.205183715792742];
    dt = [0.15 0.15 0.15];

    orientation = [0.260688194782513 117.169708195367 15.8773073008138];

    onsetX = [-11.7210467078142 -1.64344195579843 9.90355462400871];
    onsetY = [-4.87948877439386 12.5738121376389 -8.52499241118444];
    onsetT = [0.65 0.55 0.55];

    color = [0.5 0.5 0.5; 0.5 0.5 0.5; 0.5 0.5 0.5];
    
    %eye tracking parameters
    fixationSettleTime = 0.35;
    fixationAverageTime = 0.1;
    coarseFixationWindow = 3;
    fineFixationWindow = 1.5; %why must it be so large?
    targetSaccadeWindow = 5;
    targetSaccadeSettle = 0.3;
    targetTrackingWindow = 3;
    targetTrackingDuration = 0.7;
    cueJump = [-0.0872 -0.0489];
    cueJumpDuration = 0.1;
    saccadeMaxLatency = 0.5;
    successTones = [750 0.05 0 750 0.2 0.9];
    failureTones = repmat([500 0.1 0.9 0 0.1 0], 1, 3);
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        successSound_ = makeBeeps(successTones, params.freq);
        failureSound_ = makeBeeps(failureTones, params.freq);

        interval = params.cal.interval;

        motion = MultiMotionProcess ...
            ( 'onsetX', onsetX ...
            , 'onsetY', onsetY ...
            , 'onsetT', onsetT ...
            , 'dx', dx ...
            , 'dy', dy ...
            , 'dt', dt ...
            , 'orientation', orientation ...
            , 'color', color ...
            );
        
        sprites = SpritePlayer(patch, motion);

        fixationPoint = FilledDisk([0 0], 0.1, params.blackIndex, 'visible', 1);

        %that's it for graphical elements. Now for the event structure:

        in = NearLoc();
        out= FarLoc();
        timer1 = RefreshTrigger();
        timer2 = RefreshTrigger();

        fixationSamples = 0;
        fixationTotal = [0 0];

        averagedFixation = [0 0];

        function awaitFixation(s)
            fixationSamples = 0;
            fixationTotal = [0 0];
            in.set(@settleFixation, fixationPoint.getLoc, coarseFixationWindow, [0 0]);
            out.unset();
            timer1.unset();
            timer2.unset();
        end

        function settleFixation(s)
            in.unset();
            out.set(@awaitFixation, fixationPoint.getLoc, coarseFixationWindow, [0 0]);
            timer1.set(@averageFixation ...
                , s.refresh + round(fixationSettleTime / interval) ...
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

            sprites.setVisible(1); %onset is counted from now...

            out.set(@failed, fixationPoint.getLoc, fineFixationWindow, averagedFixation);
            timer1.set(@cueSaccade, s.refresh + round(cue / interval));
            timer2.unset();
        end

        function cueSaccade(s)
            fixationPoint.setLoc(cueJump);
            in.set(@saccadeSettle, sprites.loc, targetSaccadeWindow, averagedFixation - cueJump);
            out.unset();
            timer1.set(@failed, s.refresh + round(saccadeMaxLatency / interval) );
            timer2.set(@fixationOff, s.refresh + round(cueJumpDuration / interval) );
            %hide the visual stimuli, await the saccades
            sprites.setDrawn(0);
            newColor = color;
            newColor(:,2:end) = 0;
            motion.setColor(newColor);
        end

        function fixationOff(s)
            fixationPoint.setVisible(0);
            timer2.unset();
        end
        
        function saccadeSettle(s)
            in.unset();
            sprites.setDrawn(1);
            out.set(@failed, sprites.loc, targetSaccadeWindow, averagedFixation);
            timer1.set(@tracking, s.refresh + round(targetSaccadeSettle/interval));
        end
            
        function tracking(s)
            timer1.set(@done, s.refresh + round(targetTrackingDuration/interval));
            out.set(@failed, sprites.loc, targetTrackingWindow, averagedFixation);
        end

        function failed(s)
            %FAIL
            result.success = 0;
            stop(s);
            PsychPortAudio('Stop', params.pahandle);
            PsychPortAudio('FillBuffer', params.pahandle, failureSound_, 0);
            PsychPortAudio('Start', params.pahandle, 1, s.next);
        end

        function done(s)
            %WIN
            result.success = 1;
            stop(s);
            PsychPortAudio('Stop', params.pahandle);
            PsychPortAudio('FillBuffer', params.pahandle, successSound_, 0);
            PsychPortAudio('Start', params.pahandle, 1, s.next);
        end

        function abort(s) %these are so you have different things in the log file
            result.abort = 1;
            stop(s);
        end

        function stop(s)
            fixationPoint.setVisible(0);
            sprites.setDrawn(0);
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
                ( {sprites, fixationPoint, gaze, outlines} ...
                , {in, out, timer1, timer2, gazeupdate} ...
                , 'keyboard', {KeyDown(@abort, 'q')} ...
                );
            outlines.set(main);
        else
            main = mainLoop ...
                ( {sprites, fixationPoint} ...
                , {in, out, timer1, timer2} ...
                , 'keyboard', {KeyDown(@abort, 'q')} ...
                );
        end

        result = struct('success', 0);
        
        awaitFixation();

        params = main.go(params);
    end

    function noop 
    end

end
