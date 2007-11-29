function this = GloLoAdjustmentTrial(varargin)

    %timing parameters
    startTime = 0;      %GetSecs value for when the trial should start (for ITI control)
    barOnset = 0;       %when the bar flashes relative to the motion stimulus
    barDuration = 1/60; %the duraiton of the bar's flash
    loopDuration = 2;   %show the animation for this many seconds then reset

    %graphics parameters
    motion = CircularMotionProcess ... %the spatial process to generate the motion
        ( 'radius', 10 ...
        , 'n', 3 ...
        , 't', 0.5 ...
        , 'phase', 0 ...
        , 'dt', 0.15 ...
        , 'dphase', 0.75 / 10 ... %dx = 0.75...
        , 'angle', 90 ...
        , 'color', [0.5;0.5;0.5] ...
        );

    patch = CauchyPatch... %the graphical element of the motion
        ( 'velocity', 10 ...
        , 'size', [0.5 0.75 0.1]...
        );
    
    barLength = 1;            %length of the bars
    barWidth = 0.1;           %width of the bars
    barRadius = 6;       %the radius of the bar(s)
    barPhase = 0; %the displacement of the bar around the circle CCW from the initial position of the object.
    barPhaseStep = 2*pi/768;     %how big the bar's step is in phase-around-circle terms
    barBackgroundColor = [0.55 0.55 0.55]; %the color of the bar when it's not flashing (the background)
    barFlashColor = [1 1 1];  %the color of the bar when it's flashing
    
    fixationPointSize = 0.1;

    %response parameters
    abortKey = 'q';          %this keypress aborts the experiment entirely (TODO: phase this out with the interruptible GUI interactive experiment)
    
    persistent init__; %#ok;
    this = autoobject(varargin{:});
   
    %performance gets a boost if we retain and re-use objects,
    %because MATLAB's garbage collection on nested function handles is
    %unbelievably slow. Even though this is incredibly ugly of a thing to
    %do...
    fixationPoint_ = FilledDisk([0 0], fixationPointSize, [0 0 0]);
    bar_ = FilledBar();
    sprites_ = SpritePlayer();
    main_ = mainLoop('graphics', {bar_, sprites_, fixationPoint_});
    barPhaseAdjustment_ = 0;
    
    function [params, result] = run(params)
        %we will fill out this structure
        result = struct ...
            ( 'success', 0 ...
            , 'abort', 0 ...
            , 'adjustment', NaN ...
            , 'startTime', NaN ...
            , 'endTime', NaN ...
            , 'isiWaitStartTime', NaN ...
            );
        
        %reset the bar position
        barPhaseAdjustment_ = 0;
        
        color = @(c)params.blackIndex + (params.whiteIndex-params.blackIndex)*c;
        
        interval = params.cal.interval;
        
        %we use these graphics objects
        %UGH i could just have just initialized these in the constructor...
        %but matlab has to be all slow...
        fixationPoint_.setRadius(fixationPointSize);
        
        sprites_.setPatch(patch);
        sprites_.setProcess(motion);
        
        bar_.setLength(barLength);
        bar_.setWidth(barWidth);
        bar_.setColor(color(barBackgroundColor));
        bar_.setAngle(180/pi*barPhase);
        positionBar();
        
        %use these triggers (depending on if we have the knob)
        keyDown = KeyDown(@abort, abortKey);
        timer = RefreshTrigger();
        knobRotate = KnobRotate();
        knobDown = KnobDown();
        
        %begin the trial with a variable delay
        timer.set(@isi, 0);
        
        %run the main loop

        main_.setInput({params.input.knob, params.input.keyboard});
        main_.setTriggers({keyDown, timer, knobRotate, knobDown});
        main_.go(params);

        %event handler functions
        function isi(s)
            %wait through the ISI
            fixationPoint_.setVisible(1);
            bar_.setVisible(1);
            result.isiWaitStartTime = s.next;
            %wait out the inter-stimulus interval
            timer.set(@start, round(s.refresh + (startTime - s.next) / interval));
        end
        
        function start(s)
            %show the motion
            result.startTime = s.next;
            knobRotate.set(@knobTurned);
            knobDown.set(@satisfiedResponse);
            restart(s);
        end

        startRefresh_ = 0;
        function restart(s)
            sprites_.setVisible(0);
            sprites_.setVisible(1);
            bar_.setVisible(1);
            startRefresh_ = s.refresh;
            %wait for the flash
            timer.set(@showBar, s.refresh + round(barOnset/interval));
        end
        
        function showBar(s)
            bar_.setColor(color(barFlashColor));
            timer.set(@hideBar, s.refresh + round(barDuration/interval));
        end
        
        function hideBar(s) %#ok
            bar_.setColor(color(barBackgroundColor));
            timer.set(@restart, startRefresh_ + round(loopDuration./interval));
        end
        
        function knobTurned(s)
            barPhaseAdjustment_ = barPhaseAdjustment_ - barPhaseStep * s.knobRotation;
            positionBar();
        end

        function positionBar()
            bar_.setX( (barRadius * cos(barPhase + barPhaseAdjustment_)));
            bar_.setY(-(barRadius * sin(barPhase + barPhaseAdjustment_)));
            bar_.setAngle(180/pi*(barPhase+barPhaseAdjustment_));
        end
        
        function satisfiedResponse(s)
            knobRotate.unset();
            timer.unset();
            
            result.success = 1;
            result.adjustment = barPhaseAdjustment_;
            stop(s);
        end
        
        function stop(s)
            fixationPoint_.setVisible(0);
            bar_.setVisible(0);
            bar_.setVisible(0);
            sprites_.setVisible(0);
            
            knobRotate.unset();
            knobDown.unset();

            timer.set(main_.stop, s.refresh+1);
            result.endTime = s.next;
        end
        
        function abort(s)
            result.abort = 1;
            stop(s);
        end
        
    end
end