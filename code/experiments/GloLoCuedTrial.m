function this = GloLoCuedTrial(varargin)

    fixationLatency = 2; %how long to wait for acquiring fixation
    
    fixationStartWindow = 3; %this much radius for starting fixation
    fixationSettle = 0.3; %allow this long for settling fixation.
    fixationWindow = 1.5; %subject must fixate this closely...

    %timing parameters
    extra = struct();
    startTime = 0;      %GetSecs value for when the trial should start (for ITI control)
    barCueOnset = 0.0;  %after acquiring fixation
    barCueDuration = 1/30; %how long to show the cue on screen
    barCueDelay = 0.5; %how long between cuing the bar position and beginning the stimulus.
    
    barOnset = 0;       %when the bar flashes relative to the motion stimulus onset
    barFlashDuration = 1/30; %the duration of the bar's flash
    stimulusDuration = Inf; %switch the sitmulus off after this long...
 
    %graphics parameters
    
    
    %buh. this is a kludge to support both smooth motion and stepped motion
    %in the same experiment.
    targets = {
        CauchySpritePlayer(...
            'process', CircularCauchyMotion ...
                ( 'radius', 8 ...
                , 'dt', 0.15 ...
                , 'dphase', 1.5/8 ... %dx = 1.5
                , 'x', 0 ...
                , 'y', 0 ...
                , 't', 0.15 ...
                , 'n', 7 ...
                , 'color', [0.5 0.5 0.5]' ...
                , 'velocity', 10 ... %velocity of peak spatial frequency
                , 'wavelength', 0.75 ...
                , 'width', 0.5 ...
                , 'duration', 0.1 ...
                , 'order', 4 ...
                ) ...
            ), ...
        CauchyDrawer( ...
            'source', CircularSmoothCauchyMotion ...
                ('radius', 8 ...
                , 'phase', 0 ...
                , 'angle', 90 ...            
                , 'omega', 0 ...
                , 'color', [0.125 0.125 0.125]' ...
                , 'wavelength', 1 ...
                , 'width', 0.5 ...
                , 'order', 4 ...
                )...
            ) ...
        };

    whichTargets = 1;
    
    patch = CauchyPatch... %the graphical element of the motion
        ( 'velocity', 10 ...
        , 'size', [0.5 0.75 0.1]...
        );
    
    barLength = 2; %length of the bars
    barWidth = 0.1; %width of the bars
    barRadius = 8; %the radius of the bar(s)
    barPhase = 0; %the displacement of the bar around the circle CCW from the initial position of the object.
    knobThreshold = 3;            %how many notches to turn the knob before it registers a response.
    barFlashColor = [1 1 1];  %the color of the bar when it's flashing
    
    fixationPointSize = 0.1; %the fixation point...

    %response parameters
    abortKey = 'q';          %this keypress aborts the experiment entirely (TODO: phase this out with the interruptible GUI interactive experiment)
    
    persistent init__; %#ok;
    this = autoobject(varargin{:});
   
    %performance gets a boost if we retain and re-use objects,
    %because MATLAB's garbage collection on nested function handles is
    %unbelievably slow. Even though this is an incredibly ugly thing to
    %do...
    fixationPoint_ = FilledDisk([0 0], fixationPointSize, [0 0 0]);
    bar_ = FilledBar();
    main_ = mainLoop();
    trigger_ = Trigger();
    evf_ = eyeVelocityFilter();
    
    function [params, result] = run(params)
        %we will fill out this structure
        result = struct ...
            ( 'success', 0 ...
            , 'abort', 0 ...
            , 'response', NaN ...
            , 'startTime', NaN ...
            , 'endTime', NaN ...
            , 'motionOnset', NaN ...
            );
        
        theTarget = targets{whichTargets};
        
        color = @(c)params.blackIndex + (params.whiteIndex-params.blackIndex)*c;
        
        interval = params.cal.interval;
        
        %we use these graphics objects
        %UGH i could just have just initialized these in the constructor...
        %but matlab has to be all slow...
        fixationPoint_.setRadius(fixationPointSize);
        fixationPoint_.setVisible(0);
        
        bar_.setLength(barLength);
        bar_.setWidth(barWidth);
        bar_.setColor(color(barFlashColor));
        bar_.setAngle(180/pi*barPhase);
        bar_.setVisible(0);
        
        %reset the trigger for this trial...
        trigger_.reset();
        
        %use these triggers (depending on if we have the knob)
        trigger_.panic(keyIsDown(abortKey), @abort);
        
        %Show the fixation point when the ISI expires.
        trigger_.singleshot(atLeast('next', startTime - interval/2), @showFixation);
                
        %run the main loop
        main_.setGraphics({bar_, fixationPoint_, theTarget});
        main_.setInput({params.input.knob, params.input.keyboard, params.input.eyes, evf_});
        main_.setTriggers({trigger_});

        positionBar();
        
        main_.go(params);

        
        
        %event handler functions
        function showFixation(s)
            %We start here, and wait through the ISI.
            fixationPoint_.setVisible(1);
            result.startTime = s.next;
            
            trigger_.first ...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fixationPoint_.getLoc, fixationStartWindow), @settleFixation, 'eyeFt' ...
                , atLeast('eyeFt', s.next + fixationLatency), @failedWaitingFixation, 'eyeFt' ...
                );
        end
        
        function failedWaitingFixation(k)
            failed(k);
        end

        function settleFixation(k)
            trigger_.first ...
                ( atLeast('eyeFt', k.triggerTime + fixationSettle), @startTrial, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixationPoint_.getLoc, fixationStartWindow), @failedSettling, 'eyeFt' ...
                );
        end
        
        function failedSettling(k)
            failed(k);
        end

        fixationBreakHandle_ = [];
        function startTrial(h)
            fixationBreakHandle_ = trigger_.singleshot(circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixationPoint_.getLoc, fixationWindow), @failedFixation);
            trigger_.singleshot(atLeast('next', h.next + barCueOnset), @showCue);
        end
        
        function failedFixation(s)
            failed(s);
        end
        
        function showCue(s)
            %show the bar flash position
            bar_.setVisible(1);
            trigger_.singleshot(atLeast('next', s.next + barCueDuration - interval/2), @hideCue);
        end
        
        function hideCue(s)
            bar_.setVisible(0);
            %clever bit: since the Cauchy sprite player runs on timestamps
            %and not refreshes, I can schedule it from the beginning.
            result.motionStartTime = theTarget.setVisible(1, s.next + barCueDelay);

            %schedule the bar flash to occur
            trigger_.singleshot(atLeast('next', s.next + barCueDelay + barOnset - interval/2), @showBar);
            
            if stimulusDuration < Inf
                trigger_.singleshot(atLeast('next', s.next + barCueDelay + stimulusDuration), @hideStimulus);
            end
        end
        
        function showBar(s)
            bar_.setVisible(1);
            trigger_.singleshot(atLeast('next', s.next + barFlashDuration - interval/2), @hideBar);
        end
        
        function hideBar(s)
            bar_.setVisible(0);
            trigger_.singleshot(atLeast('refresh', s.refresh + 2), @awaitInput);
        end
        
        function awaitInput(s)
            %this is moved into a following event in order to calm frame
            %skips...

            %now wait for a response : Knob rotating CW, knob rotating CCW, or knob pressed to
            %skip. Fixation breaks are allowed from this point.
            
            trigger_.remove(fixationBreakHandle_);
            trigger_.mutex ...
                ( atLeast('knobPosition', s.knobPosition + knobThreshold), @knobCW ...
                , atMost('knobPosition', s.knobPosition - knobThreshold), @knobCCW ...
                , atLeast('knobDown', 1), @knobPressed ...
                )
        end
        
        function hideStimulus(s)
            theTarget.setVisible(0);
        end
        
        function knobCW(s)
            result.response = 1;
            result.success = 1;
            stop(s);
        end
        
        function knobCCW(s)
            result.response = -1;
            result.success = 1;
            stop(s);
        end
        
        function knobPressed(s)
            result.response = 0;
            result.success = 0;
            stop(s);
        end
        
        function stop(s)
            fixationPoint_.setVisible(0);
            bar_.setVisible(0);
            theTarget.setVisible(0);
            
            trigger_.singleshot(atLeast('refresh', s.refresh+1), main_.stop);
            result.endTime = s.next;
        end
        
        function failed(s)
            result.success = 0;
            stop(s);
        end
        
        function abort(s)
            result.abort = 1;
            result.success = 0;
            
            stop(s);
        end

        function positionBar()
            bar_.setX( (barRadius * cos(barPhase)));
            bar_.setY(-(barRadius * sin(barPhase)));
        end
        
    end
end