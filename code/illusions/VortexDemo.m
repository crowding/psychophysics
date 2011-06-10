function this = VortexDemo(varargin)

    angle_ = 30; %
    local_angle = 30;
    dt_ = 1/10;
    duration_ = 2/30;
    period_mult_ = 3/30; %controls local spatial frequency
    period_step_ = 1; %how many periods per step; controls global velocity
    velocity_factor_ = -2/3; %local velocity as a factor of global?
    outfile = '';
    
    my_ = Genitive();

    sprites = CauchySpritePlayer('process', VortexCauchyMotion...
        ( my_.arcPhaseSpacing, pi/3 ... %down to pi/3
        , my_.logRadiusSpacing, 0.9 ...% down to 0.3
        , my_.logRadius, 1 ...
        , my_.angle, local_angle ...
        , my_.order, 5 ...
        , my_.duration, duration_ ...
        , my_.wavelength_mult, period_mult_ ...
        , my_.dt, dt_ ...
        , my_.width_mult, 0.14 ...
        , my_.maxLogRadius, log(11) ...
        , my_.minLogRadius, log(11)-3 ...
        , my_.velocity_mult, velocity_factor_ * period_step_ * period_mult_ / dt_ ...
        , my_.dLogRadius, -period_mult_ * period_step_ * sin(angle_*pi/180) ...
        , my_.dArcPhase, period_mult_ * period_step_ * cos(angle_*pi/180) ...
        , my_.dLocalPhase, 0 ... %2*pi*period_step_ + 2*pi*dt_*period_step_*velocity_factor_ ...
        , my_.localPhase, pi/2 ...
        , my_.color, [1; 1; 1]/2 ...
        ));
    
    loopLength = findLoop(80:130) % I come up with 122 here, ok
    
    %find that looping number.
    %specifically what is the least integer N that makes:
    %N * dArcPhase =  m * arcPhaseSpacing and 
    %N * dLogRadius = k * logRadiusSpacing
    %for some M,K integers
    
    function best = findLoop(N)
        %this be some complicated-ass fudging, what we want to do is
        %slightly adjust the dArcPhase and dLogSpacing to make a match in
        %the range of times, given, with the least effect on the... score?
        dArcPhase = sprites.property__(my_.process.dArcPhase);
        dLogRadius = sprites.property__(my_.process.dLogRadius);
        arcPhaseSpacing = sprites.property__(my_.process.arcPhaseSpacing);
        logRadiusSpacing = sprites.property__(my_.process.logRadiusSpacing);
        
        ma = mod(dArcPhase * N, arcPhaseSpacing)/ arcPhaseSpacing;
        mr = mod(dLogRadius * N, logRadiusSpacing) / logRadiusSpacing;
        
        adj_da = arcPhaseSpacing./N .* round(dArcPhase.*N./arcPhaseSpacing);
        adj_dr = logRadiusSpacing./N .* round(dLogRadius.*N./logRadiusSpacing);
        
        %the score is penalized by how far you adjusted both spacings,
        %as well as how far you adjusted their sum and their angle.
        sa = ((dArcPhase - adj_da)/dArcPhase).^2;
        sr = ((dLogRadius - adj_dr)/dLogRadius).^2;
        ss = wrap(atan2(dArcPhase, dLogRadius) - atan2(adj_da, adj_dr), -pi, 2*pi);
        score = sa + sr;
        
        ibest = getOutput(2, @min, score);
        best = N(ibest);
        
        subplot(4, 1, 1);
        plot(N, sa)
        subplot(4, 1, 2);
        plot(N, sr);
        subplot(4,1,3);
        plot(N, ss);
        subplot(4,1,4);
        plot(N, score);
        
        sprites.property__(my_.process.dArcPhase, adj_da(ibest));
        sprites.property__(my_.process.dLogRadius, adj_dr(ibest));
    end
        
    fixation = FilledDisk([0;0], 0.1, 0, 'visible', 1);
    surround = FilledAnnularSector...
        ('arcAngle',2*pi ...
        , 'innerRadius', 10 ...
        , 'outerRadius', 20 ...
        , 'visible', 1 ...
        , 'color', [0.4 0.4 0.4]*255);
    fixsurr = FilledDisk([0;0], 1, 127.5, 'visible', 1)

    persistent init__;
    
    this = autoobject(varargin{:});
    
    if ~isempty(outfile)
        playDemo(this, 'aviout', outfile);
    else
        playDemo(this, varargin{:});
    end
    
    function params = getParams() 
        params = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 0  ...
        , 'preferences', struct('skipSyncTests', 1, 'TextAntiAliasing', 1 ) ...
        , 'requireCalibration', 0 ...
        , 'hideCursor', 0 ...
        , 'aviout', '' ...
        , 'avistart', 2 ...
        , 'avirect', [0 0 512 512] ...
        , 'rect', [0 0 512 512]...
        , 'cal', Calibration('interval', 1/60, 'distance', 180/pi, 'spacing', [20/512, 20/512], 'rect', [0 0 512 512]) ...
        , 'priority', 0 ...
        );
    end

    function params = run(params)
        
        trigger = Trigger();
       
        main = mainLoop ...
            ( 'graphics', {sprites, fixsurr, fixation, surround} ...
            , 'triggers', {trigger} ...
            , 'input',    {params.input.keyboard} ...
            );
        
        trigger.singleshot(atLeast('refresh', 0), @start);
        
        trigger.singleshot(keyIsDown({'LeftControl', 'ESCAPE'}, {'RightGUI', 'ESCAPE'}, 'End', 'ESCAPE'), main.stop);
        trigger.multishot(keyIsDown('1!'), @grgt);
        trigger.multishot(keyIsDown('2@'), @grlt);
        trigger.multishot(keyIsDown('3#'), @lrlt);
        trigger.multishot(keyIsDown('4$'), @lrgt);
        
        params = main.go(params);

        function start(status)
            sprites.setVisible(1, status.next);
            %wait for the looplength...
            trigger.singleshot(atLeast('next', status.next + floor(loopLength * 1.25) * dt_  - 0.005),    @grlt);
            trigger.singleshot(atLeast('next', status.next + floor(loopLength * 2.5) * dt_   - 0.005),    @lrlt);
            trigger.singleshot(atLeast('next', status.next + floor(loopLength * 3.75) * dt_ - 0.005),     @lrgt);
            trigger.singleshot(atLeast('next', status.next + floor(loopLength * 5) * dt_    - 0.005),     main.stop);
        end
        
        function grgt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/3);
            sprites.property__(my_.process.logRadiusSpacing, 0.9);
            
            sprites.property__(my_.process.arcPhaseSkew,  0);
            sprites.property__(my_.process.logRadiusSkew, 0);
        end
    
        function grlt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/9);
            sprites.property__(my_.process.logRadiusSpacing, 0.9);
            
            sprites.property__(my_.process.arcPhaseSkew,  0);
            sprites.property__(my_.process.logRadiusSkew, 0);
        end
        
        function lrlt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/9);
            sprites.property__(my_.process.logRadiusSpacing, 0.3);
            
            sprites.property__(my_.process.arcPhaseSkew, -7/18);
            sprites.property__(my_.process.logRadiusSkew, 11/18);
            
        end
        
        function lrgt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/3);
            sprites.property__(my_.process.logRadiusSpacing, 0.3);
            
            sprites.property__(my_.process.arcPhaseSkew,  0);
            sprites.property__(my_.process.logRadiusSkew, 1/6);
        end

    end
end

