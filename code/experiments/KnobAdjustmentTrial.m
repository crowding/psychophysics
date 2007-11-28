function this = KnobAdjustmentTrial(varargin)

    %timing parameters
    startTime = 0;
    barOnset = 0;
    barDuration = 1/60;

    %graphics parameters
    motion = CircularMotionProcess ...
        ( 'radius', 10 ...
        , 'n', 3 ...
        , 't', 0.5 ...
        , 'phase', 0 ...
        , 'dt', 0.15 ...
        , 'dphase', 0.75 / 10 ... %dx = 0.75...
        , 'angle', 90 ...
        , 'color', [0.5;0.5;0.5] ...
        );

    patch = CauchyPatch...
        ( 'velocity', 10 ...
        , 'size', [0.5 0.75 0.1]...
        );
    
    barInnerLength = 1;
    barOuterLength = 1;
    barWidth = 0.1;
    barGap = 1;
    barRadius = 10;
    barPhaseDisplacement = 0;
    
    fixationPointSize = 0.1;

    %response parameters
    cwResponseKey = 'x';
    ccwResponseKey = 'z';
    satisfiedResponseKey = 'space';
    abortKey = 'q';
    knobTurnThreshold = 3;
    
    persistent init__; %#ok;
    this = autoobject(varargin{:});
   
    function [params, result] = run(params)
        checkpoint();
        %we will fill out this structure
        result = struct ...
            ( 'success', 0 ...
            , 'abort', 0 ...
            , 'direction', NaN ...
            , 'startTime', 0 ...
            , 'endTime', 0 ...
            );

        barPhase = motion.getPhase() + barPhaseDisplacement;
        barPhase = barPhase(1);
        motionPhase = motion.getPhase();
        
        
        interval = params.cal.interval;
        
        %we use these graphics objects
        fixationPoint = FilledDisk([0 0], fixationPointSize, [0 0 0]);
        sprites = SpritePlayer(patch, motion);
        innerBar = FilledBar...
            ( 'x', (barRadius - (barGap + barInnerLength) / 2) * cos(barPhase)...
            , 'y', -(barRadius - (barGap + barInnerLength) / 2) * sin(barPhase)...
            , 'length', barInnerLength, 'width', barWidth...
            , 'color', params.whiteIndex, 'angle', 180/pi*barPhase);
        outerBar = FilledBar...
            ( 'x', (barRadius + (barGap + barOuterLength) / 2) * cos(barPhase)...
            , 'y', -(barRadius + (barGap + barOuterLength) / 2) * sin(barPhase)...
            , 'length', barOuterLength, 'width', barWidth...
            , 'color', params.whiteIndex, 'angle', 180/pi*barPhase);
        
        %use these triggers (depending on if we have the knob)
        keyDown = KeyDown(@abort, abortKey);
        timer = RefreshTrigger();
        
        
        if (isfield(params.input, 'knob'))
             setResponse = @setKnobResponse;
             unsetResponse = @unsetKnobResponse;
             input = {params.input.knob, params.input.keyboard};
             knobDown = KnobDown();
             knobThreshold = KnobThreshold();
             triggers = {keyDown, timer, knobDown, knobThreshold};
        else
             setResponse = @setKeyboardResponse;
             unsetResponse = @unsetKeyboardResponse;
             input = {params.input.keyboard};
             triggers = {keyDown, timer};
        end
        
        %begin the trial with a variable delay
        timer.set(@isi, 0);
        
        %make and run the main loop

        %The profiler LIES and tells me this is the bottleneck when it
        %sure ain't...
        checkpoint();
        main = mainLoop ...
            ( 'input', input ...
            , 'triggers', triggers ...
            , 'graphics', {sprites, fixationPoint, innerBar, outerBar} ...
            );
        checkpoint();
        main.go(params);
        checkpoint();
        clear knobDown knobThreshold triggers main barPhase motionPhase interval fixationPoint sprites innerBar outerBar keyDown timer setResponse unsetResponse input
        checkpoint();
        %%%PERF NOTE clearing these variables takes FOREVER for some reason --44.9/24 trials)

        %event handler functions
        
        function isi(s)
            %wait through the ISI
            fixationPoint.setVisible(1);
            result.isiWaitStartTime = s.next;
            %wait out the inter-stimulus interval
            timer.set(@start, round(s.refresh + (startTime - s.next) / interval));
        end
        
        function start(s)
            %show the motion
            sprites.setVisible(1);
            result.startTime = s.next;
            
            %wait for the flash
            timer.set(@showBar, s.refresh + round(barOnset/interval));
        end
        
        function showBar(s)
            innerBar.setVisible(1);
            outerBar.setVisible(1);
            timer.set(@hideBar, s.refresh + round(barDuration/interval));
        end
        
        function hideBar(s) %#ok
            innerBar.setVisible(0);
            outerBar.setVisible(0);
            timer.unset();
            setResponse(s); %calls either setKeyboardResponse or setKnobResponse
        end
        
        function setKeyboardResponse(s)
            keyDown.set...
                ( {@cwResponse, @ccwResponse, @satisfiedResponse}...
                , {cwResponseKey, ccwResponseKey, satisfiedResponseKey});
        end
        
        function unsetKeyboardResponse(s) %#ok
            keyDown.unset({cwResponseKey, ccwResponseKey, satisfiedResponseKey});
        end
        
        function setKnobResponse(s) %#ok
            %clockwise on the knob is positive, despite CCW in graphics
            %being positive
            knobThreshold.set(@cwResponse, s.knobPosition + knobTurnThreshold, @ccwResponse, s.knobPosition-knobTurnThreshold);
            knobDown.set(@satisfiedResponse);
        end
        
        function unsetKnobResponse(s) %#ok
            knobThreshold.unset();
            knobDown.unset();
        end
        
        function cwResponse(s)
            unsetResponse(s);
            result.direction = -1;
            result.success = 1;
            stop(s);
        end
        
        function ccwResponse(s)
            unsetResponse(s);
            result.direction = 1; %onscreen, positive rotation is CCW. 
            result.success = 1;
            stop(s);
        end
        
        function satisfiedResponse(s)
            unsetResponse(s);
            result.direction = 0;
            result.success = 1;
            stop(s);
        end
        
        function stop(s)
            fixationPoint.setVisible(0);
            innerBar.setVisible(0);
            outerBar.setVisible(0);
            sprites.setVisible(0);
            
            unsetResponse(s);

            timer.set(main.stop, s.refresh+1);
            result.endTime = s.next;
        end
        
        function skip(s)
            result.success = 0;
            stop(s);
        end
        
        function abort(s)
            result.abort = 1;
            stop(s);
        end
        
    end
end