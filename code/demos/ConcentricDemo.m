function params = ConcentricDemo(varargin)
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
    
    params = require(getScreen(params), @runDemo);
    
    function params = runDemo(params)
        interval = params.cal.interval; %screen refresh interval

        radius = 12; %approximate radius
        n = 10; %number in each wheel
        dx = 0.75; %translation per appearance
        dt = .15; %time interval between appearances
        contrast = 1; %contrast of each appearance (they superpose)
                
        %spatiotemporal structure of each appearance:        
        phases = (1:n) * 2 * pi / n; %distribute evenly around a circle
        times = (0:n-1) * 0; %dt/n - 2*dt; %onset times are staggered to avoid strobing appearance, and start "before" 0 to have a fully formed wheel at the first frame
        
        original_properties = ...
            { 'radius', radius ...
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
            , 'phase', phases ...
            , 't', times ...
            };
        
        motion = CircularCauchyMotion(original_properties{:});
        
        distribute();
        
        sprites = CauchySpritePlayer('process', motion);
        
        text = Text('loc', [-15 -15], 'Color', [0 0 0]);

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
        keyboard.set(@(h)multiply(motion, 'velocity', sqrt(1.5), h),         ']}');
        keyboard.set(@(h)multiply(motion, 'velocity', 1/sqrt(1.5), h),         '[{');

        keyboard.set(@(h)multiply(motion, 'dphase', -1, h),        'x');
        keyboard.set(@(h)multiply(motion, 'velocity', -1, h),        'z');

        keyboard.set(@more, '=+');
        keyboard.set(@less, '-_');
        
        keyboard.set(@(h) multiply(motion, 'radius', sqrt(1.5), h), 'RightArrow');
        keyboard.set(@(h) multiply(motion, 'radius', 1/sqrt(1.5), h), 'LeftArrow');

        keyboard.set(@(h) multiply(motion, 'dphase', sqrt(1.5), h), '''"');
        keyboard.set(@(h) multiply(motion, 'dphase', 1/sqrt(1.5), h), ';:');

        keyboard.set(@(h) multiply(motion, 'wavelength', 1/sqrt(1.5), h), '9(');
        keyboard.set(@(h) multiply(motion, 'wavelength', sqrt(1.5), h), '0)');
        
        keyboard.set(@(h) multiply(motion, {'dt', 'duration'}, 1/sqrt(1.5), h), 'o');
        keyboard.set(@(h) multiply(motion, {'dt', 'duration'}, sqrt(1.5), h), 'p');

        keyboard.set(@(h)multiply(motion, {'radius', 'wavelength', 'velocity'}, 1/sqrt(1.5), h), ',<');
        keyboard.set(@(h)multiply(motion, {'radius', 'wavelength', 'velocity'}, sqrt(1.5), h), '.>');

        keyboard.set(@displaytoggle, 'space');
        
        keyboard.set(@pause, '`~');
        
        keyboard.set(main.stop, 'q');
        
        keyboard.set(@reset, 'ESCAPE');

        release_trigger = [];
        
        params = require(initparams(params), keyboardInput.init, main.go);
        
        function start(h)
            sprites.setVisible(1, h.next);
            if ~isempty(params.aviout)
                timer.set(main.stop, h.refresh + nFrames);
            end
            display(h);
        end
        
        function reset(h)
            motion.property__(original_properties{:});
            n = 8;
            distribute();
            display(h);
        end
        
        function multiply(object, property, factor, h)
            if ~iscell(property)
                property = {property};
            end
            for i = property(:)'
                object.property__(property{1}, object.property__(property{1}) .* factor);
            end
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
        
        function distribute()
            phases = (1:n) * 2 * pi / n; %distribute evenly around a circle
            times = (0:n-1) * 0;
            %phaseadj = dx/dt / radius * times; %compensate positions for staggered onset times
            
            motion.setPhase(phases); % - phaseadj ...
            motion.setAngle(90 + phases * 180/pi); %(phases - phaseadj) * 180 / pi ...
            motion.property__('t', times);
        end
        
        displayon_ = 0;
        function display(h)
            string = sprintf('+ - n=%d\n<-->r=%0.2g\n'' ; dx=%0.2g\no p dt=%0.2g\n[ ] v=%0.2g\n(  ) l=%0.2g\nw=%0.2g', n, motion.getRadius(), motion.getDphase() .* motion.getRadius(), motion.getDt(), motion.getVelocity(), motion.getWavelength(), motion.getWidth());
            text.setText(string);
            text.setVisible(1);
            
            if ~isempty(release_trigger)
                trigger.remove(release_trigger);
            end
            release_trigger = trigger.singleshot(atLeast('next', h.next + 5), @displayoff);
            displayon_ = 1;
        end
        
        function displayoff(h)
            release_trigger = [];
            text.setVisible(0);
            displayon_ = 0;
        end
        
        function displaytoggle(h)
            if displayon_
                displayoff(h);
            else
                display(h);
            end
        end
        
        function pause(h)
            assignin('base', 'image', Screen('GetImage', params.window));
            KbPressWait();
        end
    end
end
