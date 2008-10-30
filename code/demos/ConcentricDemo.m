function ConcentricDemo(varargin)
%show glolo concentric in a circle around the fixation point. Verious
%button presses adjust the position...

    params = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        , 'hideCursor', 0 ...
        , 'aviout', '' ...
        );
    
    params = namedargs(localExperimentParams(), params, varargin{:});
    
    require(getScreen(params), @runDemo);
    
    function runDemo(params)
        interval = params.cal.interval; %screen refresh interval

        radius = 15; %approximate radius
        n = 10; %number in each wheel
        dx = 0.75; %translation per appearance
        dt = .15; %time interval between appearances
        contrast = 1; %contrast of each appearance (they superpose)
        
%{
        %To make a looped movie, the radius should be adjusted so that a
        %whole number of transpations brings the spot back exactly.
        radius = round(radius*2*pi/dx)*dx/2/pi %adjusted radius (will print out)
        period = radius*2*pi*dt/dx %time taken for a full rotation (will print out)
        
        %how many frames to render (1 full rotation)
        nFrames = round(period / interval)
%}
        
        %spatiotemporal structure of each appearance:        
        phases = (1:n) * 2 * pi / n; %distribute evenly around a circle
        times = (0:n-1) * 0; %dt/n - 2*dt; %onset times are staggered to avoid strobing appearance, and start "before" 0 to have a fully formed wheel at the first frame
        phaseadj = dx/dt / radius * times; %compensate positions for staggered onset times
        
        motion = CircularCauchyMotion ...
            ( 'radius', radius ...
            , 'dt', dt ...
            , 'dphase', dx / radius ...
            , 'x', 0 ...
            , 'y', 0 ...
            , 'color', [contrast contrast contrast]' / 3 ...
            , 'velocity', -5 ... %velocity of peak spatial frequency
            , 'wavelength', 0.5 ...
            , 'width', 0.5 ...
            , 'duration', 0.1 ...
            , 'order', 4 ...
            );
        
        motion = CircularCauchyMotion ...
            ( 'radius', 10 ...
            , 'dt', 0.15 ...
            , 'dphase', 0.75/10 ...
            , 'x', 0 ...
            , 'y', 0 ...
            , 'color', [0.5 0.5 0.5]' ...
            , 'velocity', -5 ... %velocity of peak spatial frequency
            , 'wavelength', 0.5 ...
            , 'width', 0.5 ...
            , 'duration', 0.1 ...
            , 'order', 4 ...
            );
        
        distribute()
        
        sprites = CauchySpritePlayer('process', motion);
        
        text = Text('loc', [-15 15], 'Color', [0 0 0]);

        fixation = FilledDisk([0 0], 0.1, 0, 'visible', 1);

        keyboardInput = KeyboardInput();
        
        trigger = Trigger();
        keyboard = KeyDown();
       
        main = mainLoop ...
            ( 'graphics', {sprites, fixation, text} ...
            , 'triggers', {trigger, keyboard} ...
            , 'input', {keyboardInput} ...
            );
        
        trigger.singleshot(atLeast('refresh', 0), @start);
        
        %set some keys...
        keyboard.set(@(h)shift(motion, 'velocity', 1, h),         ']}');
        keyboard.set(@(h)shift(motion, 'velocity', -1, h),         '[{');

        keyboard.set(@(h)multiply(motion, 'dphase', -1, h),        'x');
        keyboard.set(@(h)multiply(motion, 'velocity', -1, h),        'z');

        
        keyboard.set(@more, '=+');
        keyboard.set(@less, '-_');
        
        keyboard.set(@stepmore, 'RightArrow');
        keyboard.set(@stepless, 'LeftArrow');
        keyboard.set(@(h)shift(motion, 'dt', 0.03, h),        'UpArrow');
        keyboard.set(@(h)shift(motion, 'dt', -0.03, h),        'DownArrow');

        keyboard.set(@wider, '0)');
        keyboard.set(@narrower, '9(');
        
        keyboard.set(@scaledown, ',<');
        keyboard.set(@scaleup, '.>');

        keyboard.set(@display, 'space');
        
        keyboard.set(@pause, '`~');
        
        keyboard.set(main.stop, 'q');

        release_trigger = [];
        
        params = require(initparams(params), keyboardInput.init, main.go);
        
        function start(h)
            sprites.setVisible(1, h.next);
            if ~isempty(params.aviout)
                timer.set(main.stop, h.refresh + nFrames);
            end
            display(h);
        end

        function scaledown(h)
           r = motion.getRadius();
           rn = r-1;
           
           motion.setRadius(motion.getRadius() .* (rn./r));
           %motion.setWidth(motion.getWidth() .* (rn./r));
           motion.setWavelength(motion.getWavelength() .* (rn./r));
           motion.setVelocity(motion.getVelocity() .* (rn./r));
        end
        
        function scaleup(h)
           r = motion.getRadius();
           rn = r+1;

           motion.setRadius(motion.getRadius() .* (rn./r));
           %motion.setWidth(motion.getWidth() .* (rn./r));
           motion.setWavelength(motion.getWavelength() .* (rn./r));
           motion.setVelocity(motion.getVelocity() .* (rn./r));
        end
        
        function shift(object, property, increment, h)
            object.property__(property, object.property__(property) + increment);
            display(h);
        end
        
        function multiply(object, property, factor, h)
            object.property__(property, object.property__(property) .* factor);
            display(h);
        end
        
        function more(h)
            n = n + 1;
            distribute();
            display(h);
        end
        
        function less(h)
            n = n-1;
            distribute();
            display(h);
        end
        
        function wider(h) %#ok
            r = motion.getRadius();
            motion.setDphase(motion.getDphase() ./ (r+1) .* r)
            motion.setRadius(r+1);
            display(h);
        end
           
        function narrower(h) %#ok
            r = motion.getRadius();
            motion.setDphase(motion.getDphase() ./ (r-1) .* r)
            motion.setRadius(r-1);
            display(h);
        end
        
        function stepmore(h)
            r = motion.getRadius();
            motion.setDphase((motion.getDphase() .* r + 0.1) ./ r)
            display(h);
        end
            
        function stepless(h)
            r = motion.getRadius();
            motion.setDphase((motion.getDphase() .* r - 0.1) ./ r)
            display(h);
        end
        
        function distribute()
            phases = (1:n) * 2 * pi / n; %distribute evenly around a circle
            times = (0:n-1) * 0; %dt/n - 2*dt; %onset times are staggered to avoid strobing appearance, and start "before" 0 to have a fully formed wheel at the first frame
            %phaseadj = dx/dt / radius * times; %compensate positions for staggered onset times
            
            motion.setPhase(phases); % - phaseadj ...
            motion.setAngle(90 + phases * 180/pi); %(phases - phaseadj) * 180 / pi ...
            motion.property__('t', times);
        end
            
        function display(h)
            string = sprintf('n = %d r = %g  dx = %g dt = %g v = %g', n, motion.getRadius(), motion.getDphase() .* motion.getRadius(), motion.getDt(), motion.getVelocity());
            text.setText(string);
            text.setVisible(1);
            
            if ~isempty(release_trigger)
                trigger.remove(release_trigger);
            end
            release_trigger = trigger.singleshot(atLeast('next', h.next + 5), @displayoff);
        end
        
        function displayoff(h)
            release_trigger = [];
            text.setVisible(0);
        end
        
        function pause(h)
            assignin('base', 'image', Screen('GetImage', params.window));
            KbPressWait();
        end
    end
end
