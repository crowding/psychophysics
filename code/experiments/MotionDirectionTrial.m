function this = MotionDirectionTrial(varargin)

    persistent init__;
    this = autoobject(varargin{:});

    %the graphics objects
    fixation = FilledDisk('loc', [0 0], 'color', [0;255;0], 'radius', 0.1);
    tCorrect = FilledDisk('loc', [8 0], 'color', [255;0;0], 'radius', 0.5);
    tIncorrect = FilledDisk('loc', [-8 0], 'color', [255;0;0], 'radius', 0.5);
    dots = ShadlenDots();
    
    fixationWindow = 2; %degrees radius
    targetWindow = 3; %degrees radius
    
    function [params, result] = run(params)
        trigger = Trigger();
        result = struct();
        
        main = mainLoop...
            ( 'input', {params.input.mouse, params.input.keyboard, params.input.audioout}...
            , 'graphics', {fixation, tCorrect, tIncorrect, dots}...
            , 'triggers', {trigger});
        
        trigger.panic(keyIsDown('ESCAPE'), main.stop);
        
        tCorrect.setVisible(1);
        tIncorrect.setVisible(1);
        fixation.setVisible(1);
        dots.setVisible(0);
        
        trigger.singleshot(atLeast('refresh', 0), @start);
        
        function start(status)
            fixation.setVisible(1, status.next);
            result.onset = status.next;
            trigger.singleshot...
                ( circularWindowEnter('mousex_deg', 'mousey_deg', 'mouset', fixation.getLoc, fixationWindow), @startMotion);
        end
        
        function startMotion(status)
            dots.setVisible(1, status);
            trigger.first...
                ( circularWindowEnter('mousex_deg', 'mousey_deg', 'mouset', tCorrect.getLoc, targetWindow), @correct, 'mouset' ...
                , circularWindowEnter('mousex_deg', 'mousey_deg', 'mouset', tIncorrect.getLoc, targetWindow), @incorrect, 'mouset' ...
                );
        end
        
        function correct(status)
            result.correct = 1;
            dots.setVisible(0);
            [start, finish] = params.input.audioout.play('ding');
            trigger.singleshot(atLeast('next', finish), main.stop);
        end
        
        function incorrect(status)
            result.correct = 0;
            dots.setVisible(0);
            [start, finish] = params.input.audioout.play('buzz');
            trigger.singleshot(atLeast('next', finish), main.stop);
        end
                
        function failed()
            stop();
        end

        params = main.go(params);
    end

    function result = demo(varargin)
        [params, result] = require(getScreen(namedargs(localExperimentParams(), 'initInput', 1, 'backgroundColor', [0;0;0], varargin{:})), @run);
    end
end