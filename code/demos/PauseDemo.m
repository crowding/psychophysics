function PauseDemo(varargin)
    params = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        , 'hideCursor', 0 ...
        , 'aviout', '' ...
        );
    
    params = namedargs(locaLExperimentParams(), params, varargin{:});
    
    require(getScreen(params), @runDemo);
    function runDemo(params)
        
        %just a list of the parameters we will be showing and looping
        %through...
        
        %let's make a very simple glolo....
        %x, y, t, a, color(:)', wavelength, width, duration, velocity, phase, order]; %growing in a loop; bad form
            %                 1  2  3  4  5 6 7      8           9      10        11        12     13 -

        %we will use struct for its scalar replication
        list = struct ...
            ( 'x',          num2cell((-5:5)) ...
            , 'y',          -5 ...
            , 't',          num2cell(0.15:0.15:1.65) ...
            , 'angle',      0 ...
            , 'color',      [0.5 0.5 0.5] ...
            , 'wavelength', 0.5 ...
            , 'width',      1 ...
            , 'duration',   0.1 ...
            , 'velocity',   7.5 ...
            , 'phase',      0 ...
            , 'order',      5 ...
            );
                
        list = repmat(list(:), 1, 2);
        [list(:,2).velocity] = deal(-7.5)
        list(6,2).velocity = 0;
        list(6,1).velocity = 0;
        list(6,2).duration = 0.05;
        list(6,1).duration = 0.05;
        
        list(6,1).x = 0.2;
        list(6,2).x = -0.2;
        
        %list(3,1).x = list(3,1).x;
        %list(9,2).x = list(9,2).x;
        [list(:,2).y] = deal(5);
        
        %listprocess expects a cell array, sorted by onset time...
        list = struct2cell([list(:)]);
        [tmp, i] = sort([list{3,:}]);
        list = list(:,i);
        
        process = ListProcess(list);
        
        period = 1.8;
        sprites = CauchySpritePlayer('process', process);

        %one fixation points at the center
        fixation = FilledDisk([0 0], 0.1, 0, 'visible', 1);

        keyboardInput = KeyboardInput();
        
        trigger = Trigger();
       
        main = mainLoop ...
            ( 'graphics', {sprites, fixation} ...
            , 'triggers', {trigger} ...
            , 'input', {keyboardInput} ...
            );
        
        trigger.singleshot(atLeast('refresh', 0), @start);
        trigger.panic(keyIsDown('q'), main.stop);
        
        
        
        
        params = require(initparams(params), keyboardInput.init, main.go);
        
        function start(h)
            sprites.setVisible(1, h.next);

            trigger.singleshot(atLeast('next', h.next + period), @restart);
        end

        function restart(h)
            if isfield(params, 'aviout') && ~isempty(params.aviout)
                main.stop();
            else
                sprites.setVisible(0, h.next);
                sprites.setVisible(1, h.next);
                trigger.singleshot(atLeast('next', h.triggerValue + period), @restart);
            end
        end
        
    end
end
