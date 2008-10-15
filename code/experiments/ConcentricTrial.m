%In this trial, the subect fixates at the central point, a motion occurs,
%and the subject has to respont by turning the knob let or right. Pretty
%simple...

function this = ConcentricTrial(varargin)

    startTime = 0;
    knobTurnThreshold = 3;
    awaitInput = 0.5;
    fixation = FilledDisk([0, 0], 0.1, [0 0 0]);
    
    motion = CauchySpritePlayer...
        ( 'process', CircularCauchyMotion ...
            ( 'x', 0 ...
            , 'y', 0 ...
            , 'radius', 15 ...
            , 'dphase', 1/15 ...
        ) ...
    );

    extra = struct();

    persistent init__;
    this = autoobject(varargin{:});
    

    function [params, result] = run(params)
        interval = params.screenInterval;
        
        result = struct('startTime', NaN, 'success', 0, 'abort', 0, 'response', 1);
        
        trigger = Trigger();
        trigger.panic(keyIsDown('q'), @abort);
        trigger.singleshot(atLeast('next', startTime - interval/2), @start);

        motion.setVisible(0);
        fixation.setVisible(0);
        
        main = mainLoop ...
            ( 'input', {params.input.keyboard, params.input.knob} ...
            , 'graphics', {fixation, motion} ...
            , 'triggers', {trigger} ...
            );
        
        main.go(params);
        
        function start(h)
            fixation.setVisible(1);
            motion.setVisible(1, h.next);
            trigger.singleshot(atLeast('next', h.next + awaitInput + interval/2), @waitForInput);
        end
        
        function waitForInput(h)
            trigger.first...
                ( atLeast('knobPosition', h.knobPosition+knobTurnThreshold), @cw, 'knobTime' ...
                ,  atMost('knobPosition', h.knobPosition-knobTurnThreshold), @ccw, 'knobTime' ...
                );
        end
        
        function cw(h)
            result.response = 1;
            result.success = 1;
            stop(h);
        end

        function ccw(h)
            result.response = -1;
            result.success = 1;
            stop(h);
        end
        
        function abort(h)
            result.abort = 1;
            stop(h);
        end
        
        function stop(h)
           motion.setVisible(0);
           fixation.setVisible(0);
           result.endTime = h.next;
           trigger.singleshot(atLeast('refresh', h.refresh+1), main.stop);
        end
    end
end