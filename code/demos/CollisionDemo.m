function this = CollisionDemo(varargin)
%show two glolos translating back and forth Hopefully showing local motion
%induced motion cature.
%various parameters.

    defaults_ = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        , 'hideCursor', 0 ...
        , 'aviout', '' ...
        , 'priority', 0 ...
        );
    
    motion = BacknforthCauchyMotion()

    sprites = CauchySpritePlayer('process', motion);
    
    fixation = FilledDisk([0 0], 0.1, 0, 'visible', 1);

    ambiguous_ = 0;
    displayon_ = 0;

    my_ = Genitive();
    
    presets = {
            { my_.motion.dt,           0.1 ...
            , my_.motion.color,        [0.5;0.5;0.5]/sqrt(2) ...
            , my_.motion.velocity,     [10 10] ... %velocity of peak spatial frequency
            , my_.motion.angle,        [0 90] ...
            , my_.motion.wavelength,   1.25 ...
            , my_.motion.width,        1.0 ...
            , my_.motion.duration,     2/30 ...
            , my_.motion.order,        4 ...
            , my_.motion.t,            [0 0]...
            , my_.motion.xstart,       [0 0]...
            , my_.motion.ystart,       [0 0]...
            , my_.motion.xrange,       [-10 -10; 10 10] ...
            , my_.motion.yrange,       [-10 -10; 10 10]...
            , my_.motion.dx,           [0 1]...
            , my_.motion.dy,           [1 0]...
            , my_.fixation.loc,        [10 10] ...
            }...
        };
    
    persistent init__; %#ok
    this = autoobject(presets{1}{:});
    
    function distribute()
        %if ambiguous...
        if ambiguous_
            error('not implemented!');
            %clear Screen;
            this.property__...
                ( my_.motion.x, repmat(motion.getX(), 1, 2)...
                , my_.motion.y, repmat(motion.getY(), 1, 2)...
                , my_.motion.velocity, [motion.getVelocity(), - motion.getVelocity()]...
                , my_.motion.phase, repmat(motion.getPhase(), 1, 2) ...
                , my_.motion.angle, repmat(motion.getAngle(), 1, 2) ...
                , my_.motion.t, repmat(motion.getT(), 1, 2)...
                )
        end
    end

    this.demo(varargin{:});
        
    function params = demo(varargin)
        params = require(getScreen(namedargs(localExperimentParams(), defaults_,varargin{:})), @run);
    end
    
    function params = run(params)        
        
        ttd = transformToDegrees(params.cal);
        
        text = Text('loc', ttd(params.cal.rect([1 1])) + [0.5 0.5], 'color', [0 0 0]);

        keyboardInput = KeyboardInput();
        
        trigger = Trigger();
        keyboard = KeyDown();
       
        main = mainLoop ...
            ( 'graphics', {sprites, fixation, text} ...
            , 'triggers', {trigger, keyboard} ...
            , 'input', {keyboardInput} ...
            );
        
        trigger.singleshot(atLeast('refresh', 0), @start);
        
        %set up the controls.
        status_string = '';
        status_fns = {};
        
        keyboard.set(@(h)multiply(motion, 'velocity', sqrt(sqrt(2)), h),           'q');
        keyboard.set(@(h)multiply(motion, 'velocity', 1/sqrt(sqrt(2)), h),         'a');
        status_string = [status_string 'A/Q v = %0.2g (deg/sec)\n'];
        status_fns{end+1} = @()mean(abs(motion.getVelocity()));

        keyboard.set(@(h) multiply(motion, 'wavelength', 1/sqrt(sqrt(2)), h),       's');
        keyboard.set(@(h) multiply(motion, 'wavelength', sqrt(sqrt(2)), h),         'w');
        status_string = [status_string 'S/W l = %0.2g (deg)\n'];
        status_fns{end+1} = motion.getWavelength;

        keyboard.set(@(h) multiply(motion, {'dx', 'dy'}, [sqrt(sqrt(2)) sqrt(sqrt(2))], h), 'e');
        keyboard.set(@(h) multiply(motion, {'dx', 'dy'}, [1/sqrt(sqrt(2)) 1/sqrt(sqrt(2))], h), 'd');
        status_string = [status_string 'D/E r = %0.2g (deg)\n'];
        status_fns{end+1} = @()motion.property__(my_.dx(2));

        keyboard.set(@(h) add(motion, my_.xstart(2), 0.5,  h),             'r');
        keyboard.set(@(h) add(motion, my_.xstart(2), -0.5, h),             'f');
        status_string = [status_string 'R/F x = %0.2g (deg)\n'];
        status_fns{end+1} = @()motion.property__(my_.xstart(2));

        keyboard.set(@(h) multiply(motion, 'dt', sqrt(sqrt(2)), h),             't');
        keyboard.set(@(h) multiply(motion, 'dt', 1/sqrt(sqrt(2)), h),           'g');
        status_string = [status_string 'T/G dt = %0.2g (s)\n'];
        status_fns{end+1} = motion.getDt;
        
        keyboard.set(@(h) multiply(motion, 'duration', sqrt(sqrt(2)), h),       'y');
        keyboard.set(@(h) multiply(motion, 'duration', 1/sqrt(sqrt(2)), h),     'h');
        status_string = [status_string 'Y/H d = %0.2g (s)\n'];
        status_fns{end+1} = motion.getDuration;
        
        keyboard.set(@(h) multiply(motion, 'width', sqrt(sqrt(2)), h),       'u');
        keyboard.set(@(h) multiply(motion, 'width', 1/sqrt(sqrt(2)), h),     'j');
        status_string = [status_string 'U/J w = %0.2g (deg)\n'];
        status_fns{end+1} = motion.getWidth;
        
        keyboard.set(@(h) more(motion, 'order', h),       'i');
        keyboard.set(@(h) less(motion, 'order', h),     'k');
        status_string = [status_string 'I/K o = %0.2g\n'];
        status_fns{end+1} = motion.getOrder;

        keyboard.set(@(h) multiply(motion, 'color', sqrt(sqrt(2)),h),       'o');
        keyboard.set(@(h) multiply(motion, 'color', 1/sqrt(sqrt(2)),h),     'l');
        status_string = [status_string 'O/L c = %0.2g\n'];
        status_fns{end+1} = @()mean(motion.getColor())*2;

        keyboard.set(@(h) add(motion, 'localPhase', pi/2, h),       'p');
        keyboard.set(@(h) add(motion, 'localPhase', -pi/2, h),     ';:');
        status_string = [status_string 'P/; p = %0.2g*pi\n'];
        status_fns{end+1} = @()motion.getLocalPhase()/pi;

        keyboard.set(@(h) add(motion, 'dLocalPhase', pi/16, h),       '[{');
        keyboard.set(@(h) add(motion, 'dLocalPhase', -pi/16, h),     '''"');
        status_string = [status_string '[/'' dp = %0.2g*pi\n'];
        status_fns{end+1} = @()motion.getDLocalPhase()/pi;

        keyboard.set(@(h) add(motion, my_.angle(1), 15, h),       '.>');
        keyboard.set(@(h) add(motion, my_.angle(1), -15, h),     ',<');
        status_string = [status_string ',/. angle(1) = %0.2g (deg)\n'];
        status_fns{end+1} = @()motion.property__(my_.angle(1));

        keyboard.set(@(h) add(motion, my_.angle(2), 15, h),       '-_');
        keyboard.set(@(h) add(motion, my_.angle(2), -15, h),     '=+');
        status_string = [status_string '-/= angle(2) = %0.2g (deg)\n'];
        status_fns{end+1} = @()motion.property__(my_.angle(2));
        
        keyboard.set(@ambiguous,                                                'c');
        
        status_string(end) = [];

        keyboard.set(@(h)this.property__(presets{1}{:}), '1!');
        keyboard.set(@(h)this.property__(presets{2}{:}), '2@');
        keyboard.set(@displaytoggle, 'space');
        keyboard.set(@pause, '`~');
        keyboard.set(main.stop, 'ESCAPE');
        
        release_trigger = [];
        
        motion.reset();
                
        function start(h)
            sprites.setVisible(1, h.next);
            if ~isempty(params.aviout)
                timer.set(main.stop, h.refresh + nFrames);
            end
            display(h);
        end
        
        function reset(h)
            this.property__(presets{1}{:});
            distribute();
            display(h);
        end
        
        function multiply(object, property, factor, h)
            if ~iscell(property)
                property = {property};
            end
            for i = 1:numel(property)'
                object.property__(property{i}, object.property__(property{i}) .* factor(i));
            end
            display(h);
        end
        
        function add(object, property, factor, h)
            if ~iscell(property)
                property = {property};
            end
            for i = 1:numel(property)'
                object.property__(property{i}, object.property__(property{i}) + factor(i));
            end
            display(h);
        end
        
        function more(object, property, h)
            prev = object.property__(property);
            object.property__(property, prev + 1);
            distribute();
            display(h);
        end
        
        function less(object, property, h)
            prev = object.property__(property);
            if (prev > 1)
                object.property__(property, prev - 1);
                distribute();
            end
            display(h);
        end
        
        function ambiguous(h)
            ambiguous_ = ~ambiguous_;
            %equalize energy across conditions...
            if ambiguous_
                motion.setColor(motion.getColor() / sqrt(2));
            else
                motion.setColor(motion.getColor());
            end
            distribute();
        end
        
        function display(h)
            args = cellfun(@feval, status_fns);
            string = sprintf(status_string, args);
            text.setText(string);
            text.setVisible(1);
            
            if ~isempty(release_trigger)
                trigger.remove(release_trigger);
            end
            release_trigger = trigger.singleshot(atLeast('next', h.next + 10), @displayoff);
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
            %grab a screenshot and wait...
            assignin('base', 'image', Screen('GetImage', params.window));
            KbPressWait();
        end
        
        params = require(initparams(params), keyboardInput.init, main.go);
    end
end
