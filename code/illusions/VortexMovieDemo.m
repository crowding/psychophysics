function this = VortexDemo(varargin)

    angle_ = atan(1/2)*180/pi; %for an integral step number...
    dt_ = 1/10;
    duration_ = 0.075;
    period_mult_ = 2/30; %controls local spatial frequency
    period_step_ = 1; %how many periods per step; controls global velocity
    velocity_factor_ = -2/3; %local velocity as a factor of global?
    
    my_ = Genitive();

    sprites = CauchySpritePlayer('process', VortexCauchyMotion...
        ( my_.arcPhaseSpacing, pi/9 ... %down to pi/3
        , my_.logRadiusSpacing, 0.9 ...% down to 0.3
        , my_.logRadius, 1 ...
        , my_.angle, angle_ ...
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
        , my_.color, [1; 1; 1] ...
        ));
    
    
    fixation = FilledDisk([0;0], 0.1, 0, 'visible', 1);
    surround = FilledAnnularSector...
        ('arcAngle',2*pi ...
        , 'innerRadius', 10 ...
        , 'outerRadius', 20 ...
        , 'visible', 1 ...
        , 'color', [0.4 0.4 0.4]*255);

    persistent init__;
    this = autoobject(varargin{:});
    
    playDemo(this);

    function params = run(params)
        
        trigger = Trigger();
       
        main = mainLoop ...
            ( 'graphics', {sprites, fixation, surround} ...
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
        end
        
        function grgt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/3);
            sprites.property__(my_.process.logRadiusSpacing, 0.9);
        end
    
        function grlt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/9);
            sprites.property__(my_.process.logRadiusSpacing, 0.9);
        end
        
        function lrlt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/9);
            sprites.property__(my_.process.logRadiusSpacing, 0.3);
        end
        
        function lrgt(params)
            sprites.property__(my_.process.arcPhaseSpacing, pi/3);
            sprites.property__(my_.process.logRadiusSpacing, 0.3);
        end

    end
end

