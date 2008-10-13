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
    

    function result = run(params)
        result = struct('startTime', NaN, 'success', 0, 'abort', 0, 'response', 1);
        
        trigger = Trigger();
        trigger.panic(keyIsDown('q'), @abort);
        trigger.singleshot(atLeast('next', startTime - params.interval/2), @start);

        motion.setVisible(0);
        fixation.setVisible(0);
        
        main = mainLoop ...
            ( 'input', {params.input.keyboard, params.input.knob} ...
            , 'graphics', {fixation, motion} ...
            , 'triggers', {trigger} ...
            );
        
        main.go();
        
        function start(h)
            fixation.setVisible(1);
            motion.setVisible(1, h.next);
            trigger.singleshot(atLeast('next', h.next + awaitInput + params.interval/2));
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
            trigger.singleshot(atLeast('next', h.next + params.interval/2));
        end

        function ccw(h)
            result.response = -1;
            result.success = 1;
            trigger.singleshot(atLeast('next', h.next + params.interval/2));
        end
        
        function abort(h)
            stop(h);
            result.abort = 1;
        end
        
        function stop(h)
           motion.setVisible(0);
           fixation.setVisible(0);
           result.endTime = h.next;
        end
    end
end