function this = MotionDirectionTrial(varargin)
    %this implments a trial that 

    persistent init__;
    this = autoobject(varargin{:});

    % --- The trial contains a number of properties, some of which are themselves objects: ----
    %The targets and fixation point
    fixation = FilledDisk('loc', [0 0], 'color', [0;255;0], 'radius', 0.1);
    tCorrect = FilledDisk('loc', [8 0], 'color', [255;0;0], 'radius', 0.5);
    tIncorrect = FilledDisk('loc', [-8 0], 'color', [255;0;0], 'radius', 0.5);
    
    %the dots object. it has a bunch of parameters you would set up in an
    %experiment but we use the defaults and worry about it elsewhere
    dots = ShadlenDots();
    
    fixationWindow = 2; %degrees radius
    targetWindow = 3; %degrees radius
    
    
    %each trial must have a "run" method, which returns a result structure (along
    %with passing around some global parameters.)
    %Put whatever you want into the result structure for easy analysis; for
    %more complicated analysis, remember that every trigger is logged by
    %the main loop and you can analyze those.
    
    function [params, result] = run(params)
        
        %The trigger object maintains a list of 
        trigger = Trigger();
        result = struct();
        
        %initialize the main loop with the graphics and triggers
        main = mainLoop...
            ( 'input', {params.input.mouse, params.input.keyboard, params.input.audioout}...
            , 'graphics', {fixation, tCorrect, tIncorrect, dots}...
            , 'triggers', {trigger});
        
        %At each point you can 
        trigger.panic(keyIsDown('ESCAPE'), main.stop);
        
        tCorrect.setVisible(1);
        tIncorrect.setVisible(1);
        fixation.setVisible(1);
        dots.setVisible(0);
        
        %'refresh' is one of the state variables that is collected on each
        %frame.  
        trigger.singleshot(atLeast('refresh', 0), @start);
        
        function start(status)
            %'status' is a struct that the main loop fills out; all input
            %variables (like input from input devices, and timing information) 
            %go into 'status' on each refresh.
            
            %'next' is
            %the predicted time at which any changes to the graphics
            %display will hit the screen (projected vertical blanking
            %time. THe main loop takes care of calculating that.
            %When showing an object on the scren we pass the 'onset time.'
            
            fixation.setVisible(1, status.next);
            
            %record the stimulus onset time (though in principle you could
            %derive this from the logs, which will record the fact that
            %'start' was triggered and the inputs at that point. 
            %'next' 
            
            %at the start of the experiment, we want to wait for the mouse
            %to near the "fixation" point.
            trigger.singleshot...
                ( circularWindowEnter('mousex_deg', 'mousey_deg', 'mouset', fixation.getLoc, fixationWindow), @startMotion);
        end
        
        function startMotion(status)
            %show the dots. Pass the status to the dots object so that the
            %dots object knows when the motion onset is.
            dots.setVisible(1, status);
            result.onset = status.next;
            
            %establish circular windows around each 
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