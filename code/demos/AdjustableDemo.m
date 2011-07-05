
function this = AdjustableDemo(varargin)
%show glolo concentric in a circle around the fixation point. Various
%button presses adjust the position...

%Describe the button presses here.

%Add titration
%add color balancing
    
    n = 5;
    relativeContrast = 0;
    
    motion = CircularCauchyMotion();
    sprites = CauchySpritePlayer('process', motion);
    fixation = FilledDisk([-15 15;0 0], 0.2, 0, 'visible', 1);
    occluder = FilledAnnularSector(...
                  'color', [0.475 0.475 0.475]*255 ...
                , 'loc', [0;0] ...
                , 'startAngle', 4*pi/12 ...
                , 'arcAngle', 16*pi/12 ...
                , 'innerRadius', 80/27 - 1 ...
                , 'outerRadius', 12 ...
                , 'visible', 1 ...
                );

    displayon_ = 0;
%    color_ = 0;
    
    angleShift = 0;

    my_ = Genitive();
    
    presets = {
            { my_.n, 10 ...  %single large wheel
            , my_.relativeContrast, 0 ...
            , my_.motion.dt, 0.1 ...
            , my_.motion.radius,       10 ...
            , my_.motion.dphase, .75 / 10 ...
            , my_.motion.x, 0 ...
            , my_.motion.y, 0 ...
            , my_.motion.color, [0.5 0.5 0.5]' / sqrt(2) ...
            , my_.motion.velocity,     -7.5 ... %velocity of peak spatial frequency
            , my_.motion.phase,        reshape((1:10)*2*pi/10, 1, []) ...
            , my_.angleShift,          0 ...
            , my_.motion.angle,        reshape((1:10)*360/10 + 90 + angleShift, 1, []) ...
            , my_.motion.wavelength, 0.75 ...
            , my_.motion.width, 0.5 ...
            , my_.motion.duration, 2/30 ...
            , my_.motion.order, 4 ...
            , my_.motion.t,            zeros(1, 10)...
            , my_.fixation.loc, [0;0] ...
            , my_.occluder.visible, 0 ...
            } ...
          , { my_.n,                   5 ...  %two small locally opposed wheels
            , my_.relativeContrast, 0 ...
            , my_.motion.dt,           0.099 ...
            , my_.motion.radius,       3 ...
            , my_.motion.dphase,       .5 / 3 ...
            , my_.motion.x,            repmat([-11 11], 1, 5) ...
            , my_.motion.y,            7.3 ...
            , my_.motion.color,        [0.5;0.5;0.5]/sqrt(2) ...
            , my_.motion.velocity,     repmat([-5 5], 1, 5) ... %velocity of peak spatial frequency
            , my_.motion.phase,        reshape([1;1]*(1:5)*2*pi/5, 1, []) ...
            , my_.angleShift,          0 ...
            , my_.motion.angle,        reshape([1;1]*(1:5)*360/5 + 90 + angleShift, 1, []) ...
            , my_.motion.wavelength,   0.75 ...
            , my_.motion.width,        0.5 ...
            , my_.motion.duration,     2/30 ...
            , my_.motion.order,        4 ...
            , my_.motion.t,            zeros(1, 10)...
            , my_.fixation.loc, [-11 11 0; 7.3 7.3 -11] ...
            , my_.occluder.visible, 0 ...
            }...
        };
    
    persistent init__; %#ok
    this = autoobject(presets{2}{:}, varargin{:});
    distribute();
    
    function distribute()
        %if two wheels...
        if size(fixation.getLoc(), 2) > 1
            this.property__...
                ( my_.motion.x,            [repmat(fixation.property__(my_.loc(1,[1])), 1, n), repmat(fixation.property__(my_.loc(1,[2])), 1, n)]...
                , my_.motion.y,            [repmat(fixation.property__(my_.loc(2,[1])), 1, n), repmat(fixation.property__(my_.loc(2,[2])), 1, n)] ...
                , my_.motion.velocity,     [repmat(this.property__(my_.motion.velocity(1)), 1, n), -repmat(this.property__(my_.motion.velocity(1)), 1, n)] ... %velocity of peak spatial frequency
                , my_.motion.phase,        repmat((1:n)*2*pi/n, 1, 2) ...
                , my_.motion.angle,        repmat((1:n)*360/n + 90, 1, 2) + angleShift ...
                , my_.motion.t,            zeros(1,2*n) ...
                );
        else
            this.property__...
                ( my_.motion.x,            repmat(fixation.property__(my_.loc(1)), 1, n) ...
                , my_.motion.y,            repmat(fixation.property__(my_.loc(2)), 1, n) ...
                , my_.motion.velocity,     repmat(this.property__(my_.motion.velocity(1)), 1, n) ... %velocity of peak spatial frequency
                , my_.motion.phase,        (1:n)*2*pi/n ...
                , my_.motion.angle,        (1:n)*360/n + 90 + angleShift ...
                , my_.motion.t,            zeros(1,n) ...
                );
        end
        
        %if ambiguous or titrated
        if (relativeContrast == 1)
            motion.setVelocity(sign(motion.getDphase() .* this.property__(my_.motion.velocity(1))) .* motion.getVelocity());
        else
            motion.setVelocity(-sign(motion.getDphase() .* this.property__(my_.motion.velocity(1))) .* motion.getVelocity());
        end

        if relativeContrast ~= 0 && relativeContrast ~= 1
            n_ = numel(motion.getX());
            colorOneway   = [1;1;1]/2/sqrt(2) * cos(relativeContrast*pi/2);
            colorOtherway = [1;1;1]/2/sqrt(2) * sin(relativeContrast*pi/2);
            this.property__...
                ( my_.motion.x,        repmat(motion.getX(), 1, 2)...
                , my_.motion.y,        repmat(motion.getY(), 1, 2)...
                , my_.motion.velocity, [motion.getVelocity(), - motion.getVelocity()]...
                , my_.motion.phase,    repmat(motion.getPhase(), 1, 2) ...
                , my_.motion.angle,    repmat(motion.getAngle(), 1, 2) + angleShift ...
                , my_.motion.t,        repmat(motion.getT(), 1, 2)...
                , my_.motion.color,    [repmat(colorOneway,   1, n_) repmat(colorOtherway, 1, n_)] ...
                )
        else
            motion.setColor([1;1;1]/2/sqrt(2));
        end
%         if color_
%             if ambiguous_
%                 c = repmat([0.5 0.5 0 0;0 0 0.3 0.3;0.5 0.5 0.00 0.00]/ sqrt(2), 1, ceil(n/2));
%                 c = c(:,1:2*n);
%             else
%                 c = repmat([0.5 0;0 0.5;0.25 0.25]/ sqrt(2), 1, ceil(n/2));
%                 c = c(:,1:n);
%             end
%             if size(fixation.getLoc(), 2) > 1
%                 c = [c c];
%             end
%             motion.setColor(c);
%         else
%             motion.setColor([0.5;0.5;0.5]/(sqrt(2)^(ambiguous_+1)));
%         end
    end
            
    function params = run(params)        
        
        ttd = transformToDegrees(params.cal);
        
        text = Text('loc', ttd(params.cal.rect([1 1])) + [0.5 0.5], 'color', [0 0 0]);
        
        trigger = Trigger();
        keyboard = KeyDown();
       
        main = mainLoop ...
            ( 'graphics', {sprites, occluder, fixation, text} ...
            , 'triggers', {trigger, keyboard} ...
            , 'input', {params.input.keyboard} ...
            );
        
        trigger.singleshot(atLeast('refresh', 0), @start);
        
        %set up the controls.
        status_string = '';
        status_fns = {};
        
        
        trigger.singleshot(keyIsDown({'LeftControl', 'ESCAPE'}, {'RightGUI', 'ESCAPE'}, 'End'), main.stop);
        
        keyboard.set(@(h)more(this, 'n', h),                               '=+');
        keyboard.set(@(h)less(this, 'n', h),                               '-_');
        status_string = [status_string '-/= n = %d\n'];
        status_fns{end+1} = this.getN;

        keyboard.set(@(h)multiply(motion, 'velocity', sqrt(sqrt(2)), h),   'q');
        keyboard.set(@(h)multiply(motion, 'velocity', 1/sqrt(sqrt(2)), h), 'a');
        status_string = [status_string 'A/Q v = %0.2g (deg/sec)\n'];
        status_fns{end+1} = @()mean(abs(motion.getVelocity()));

        keyboard.set(@(h) multiply(motion, 'wavelength', 1/sqrt(sqrt(2)), h),'s');
        keyboard.set(@(h) multiply(motion, 'wavelength', sqrt(sqrt(2)), h),'w');
        status_string = [status_string 'S/W l = %0.2g (deg)\n'];
        status_fns{end+1} = motion.getWavelength;

        keyboard.set(@(h) multiply(motion, {'radius', 'dphase'}, [sqrt(sqrt(2)) 1/sqrt(sqrt(2))], h), 'e');
        keyboard.set(@(h) multiply(motion, {'radius', 'dphase'}, [1/sqrt(sqrt(2)) sqrt(sqrt(2))], h), 'd');
        status_string = [status_string 'D/E r = %0.2g (deg)\n'];
        status_fns{end+1} = motion.getRadius;

        keyboard.set(@(h) multiply(motion, 'dphase', sqrt(sqrt(2)), h),    'r');
        keyboard.set(@(h) multiply(motion, 'dphase', 1/sqrt(sqrt(2)), h),  'f');
        status_string = [status_string 'R/F dx = %0.2g (deg)\n'];
        status_fns{end+1} = @()motion.getDphase() * motion.getRadius();

        keyboard.set(@(h) multiply(motion, 'dt', sqrt(sqrt(2)), h),        't');
        keyboard.set(@(h) multiply(motion, 'dt', 1/sqrt(sqrt(2)), h),      'g');
        status_string = [status_string 'T/G dt = %0.2g (s)\n'];
        status_fns{end+1} = motion.getDt;
        
        keyboard.set(@(h) multiply(motion, 'duration', sqrt(sqrt(2)), h),  'y');
        keyboard.set(@(h) multiply(motion, 'duration', 1/sqrt(sqrt(2)), h),'h');
        status_string = [status_string 'Y/H d = %0.2g (s)\n'];
        status_fns{end+1} = motion.getDuration;
        
        keyboard.set(@(h) multiply(motion, 'width', sqrt(sqrt(2)), h),     'u');
        keyboard.set(@(h) multiply(motion, 'width', 1/sqrt(sqrt(2)), h),   'j');
        status_string = [status_string 'U/J w = %0.2g (deg)\n'];
        status_fns{end+1} = motion.getWidth;
        
        keyboard.set(@(h) more(motion, 'order', h),                        'i');
        keyboard.set(@(h) less(motion, 'order', h),                        'k');
        status_string = [status_string 'I/K o = %0.2g\n'];
        status_fns{end+1} = motion.getOrder;

%         keyboard.set(@(h) multiply(motion, 'color', sqrt(sqrt(2)),h),       'o');
%         keyboard.set(@(h) multiply(motion, 'color', 1/sqrt(sqrt(2)),h),     'l');
%         status_string = [status_string 'O/L c = %0.2g\n'];
%         status_fns{end+1} = @()mean(motion.getColor())*2;

        keyboard.set(@(h) add(motion, 'localPhase', pi/2, h),              'p');
        keyboard.set(@(h) add(motion, 'localPhase', -pi/2, h),             ';:');
        status_string = [status_string 'P/; p = %0.2g*pi\n'];
        status_fns{end+1} = @()motion.getLocalPhase()/pi;

        keyboard.set(@(h) add(motion, 'dLocalPhase', pi/16, h),            '[{');
        keyboard.set(@(h) add(motion, 'dLocalPhase', -pi/16, h),           '''"');
        status_string = [status_string '[/'' dp = %0.2g*pi\n'];
        status_fns{end+1} = @()motion.getDLocalPhase()/pi;

        keyboard.set(@(h) add(this, 'angleShift',  12, h),                 ']}');
        keyboard.set(@(h) add(this, 'angleShift',  12, h),                 'Return');
        status_string = [status_string ']/RET angle = %0.2g deg\n'];
        status_fns{end+1} = this.getAngleShift;
                
        keyboard.set(@reverse,                                             'z');
        keyboard.set(@incongruent,                                         'x');
        keyboard.set(@(h)add(this,'relativeContrast', -0.10, h, 1),        'c');
        keyboard.set(@counterphase,                                        'v');
        keyboard.set(@(h)add(this,'relativeContrast',  0.10, h, 1),        'b');
        keyboard.set(@congruent,                                           'n');        
        status_string = [status_string 'c/b local content = %0.2g\n'];
        status_fns{end+1} = this.getRelativeContrast;
        
        
        keyboard.set(@occludertoggle,                                      '/?');
        keyboard.set(@(h) add(occluder, 'startAngle',  pi/4,  h),          '.>');
        keyboard.set(@(h) add(occluder, 'startAngle',  -pi/4, h),          ',<');
        status_string = [status_string '>/< occluder angle = %0.2g\n'];
        status_fns{end+1} = occluder.getStartAngle;
        
        keyboard.set(@pause,                                               'DELETE');
        status_string = [status_string '[delete] pause\n'];
        
        %strip the trailing newline escape code...
        status_string(end-1:end) = [];

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
        end
        
        function reset(h)
            this.property__(presets{1});
            distribute();
            display(h);
        end
        
        function multiply(object, property, factor, h, disto)
            if ~iscell(property)
                property = {property};
            end
            for i = 1:numel(property)
                object.property__(property{i}, object.property__(property{i}) .* factor(i));
            end
            display(h);
            if exist('disto', 'var') && disto
                distribute()
            end
        end
        
        function add(object, property, factor, h, disto)
            if ~iscell(property)
                property = {property};
            end
            for i = 1:numel(property)'
                object.property__(property{i}, object.property__(property{i}) + factor(i));
            end
            display(h);
            if exist('disto', 'var') && disto
                distribute()
            end
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

        function occludertoggle(h)
            occluder.setVisible(~occluder.getVisible());
        end
        
%         function colortoggle(h)
%             color_ = ~color_;
%             distribute();
%         end
        
        function reverse(h)
            motion.setVelocity(-motion.getVelocity());
            motion.setDphase(-motion.getDphase());
            display(h);
        end
        
        function incongruent(h)
            relativeContrast = 0;
            distribute();
            display(h);
        end
        
        function counterphase(h)
            %equalize energy across directions...
            relativeContrast = 0.5;
            distribute();
            display(h);
        end
        
        function congruent(h)
            relativeContrast = 1;
            distribute();
            display(h);
        end
        
        function pause(h)
            %grab a screenshot, write it to a file...
            [secs, code] = KbPressWait();
            if isequal(KbName(code), 'space')
                image = Screen('GetImage', params.window);
                i = 1;
                while exist(sprintf('Picture %d.png', i), 'file') || exist(sprintf('Settings %d.m', i), 'file')
                    i = i + 1;
                end

                imwrite(Screen('GetImage', params.window), sprintf('Picture %d.png', i), 'png') 
                require(openfile(sprintf('Settings %d.m', i), 'w'), @dumpme)
                disp(sprintf('Screenshot to Picture %d.png', i))
%               assignin('base', 'image', Screen('GetImage', params.window));
            end
            
            function dumpme(i)
                dump(this, @(varargin)fprintf(i.fid, varargin{:}), 'my_');
            end
        end
        
        params = main.go(params);
    end
end
