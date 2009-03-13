%In this trial, the subect fixates at the central point, a motion occurs,
%and the subject has to respont by turning the knob let or right. Pretty
%simple...

function this = ConcentricTrial(varargin)

    startTime = 0;
    knobTurnThreshold = 3;
    awaitInput = 0.5;
    fixation = FilledDisk([0, 0], 0.1, [0 0 0]);
   
    requireFixation = 1;
    fixationLatency = 2; %how long to wait for acquiring fixation
    
    fixationStartWindow = 3; %this much radius for starting fixation
    fixationSettle = 0.3; %allow this long for settling fixation.
    fixationWindow = 1.5; %subject must fixate this closely...
    reshowStimulus = 0; %whether to reshow the stimulus after the response (for training purposes)
    
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
        if requireFixation
            trigger.singleshot(atLeast('next', startTime - interval/2), @awaitFixation);
        else
            trigger.singleshot(atLeast('next', startTime - interval/2), @startMotion);
        end

        motion.setVisible(0);
        fixation.setVisible(0);
        
        if requireFixation
            main = mainLoop ...
                ( 'input', {params.input.eyes, params.input.keyboard, params.input.knob, EyeVelocityFilter()} ...
                , 'graphics', {fixation, motion} ...
                , 'triggers', {trigger} ...
                );
        else
            main = mainLoop ...
                ( 'input', {params.input.keyboard, params.input.knob} ...
                , 'graphics', {fixation, motion} ...
                , 'triggers', {trigger} ...
                );
        end
        
        main.go(params);
        
        function awaitFixation(h)
            fixation.setVisible(1);
            if requireFixation
                trigger.first ...
                    ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @settleFixation, 'eyeFt' ...
                    , atLeast('eyeFt', h.next + fixationLatency), @failedWaitingFixation, 'eyeFt' ...
                    );
            else
                trigger.singleshot(atLeast(h.next,startTime));
            end
        end
        
        function failedWaitingFixation(k)
            failed(k);
        end

        function settleFixation(k)
            trigger.first ...
                ( atLeast('eyeFt', k.triggerTime + fixationSettle), @startMotion, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @failedSettling, 'eyeFt' ...
                );
        end
        
        function failedSettling(k)
            failed(k);
        end

        
        function startMotion(h)
            fixation.setVisible(1);
            motion.setVisible(1, h.next);
            if requireFixation
                trigger.first...
                    ( atLeast('eyeFt', h.next + awaitInput), @waitForResponse, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @failedFixation, 'eyeFt' ...
                    );
            else
                trigger.singleshot(atLeast('next', h.next + awaitInput - interval/2), @waitForResponse);
            end
        end
        
        function failedFixation(h)
            failed(h)
        end
        
        function waitForResponse(h)
            trigger.first...
                ( atLeast('knobPosition', h.knobPosition+knobTurnThreshold), @cw, 'knobTime' ...
                ,  atMost('knobPosition', h.knobPosition-knobTurnThreshold), @ccw, 'knobTime' ...
                , atLeast('knobDown', 1), @failed, 'knobTime' ...
                );
        end
        
        function cw(h)
            result.response = 1;
            result.success = 1;
            if reshowStimulus
                reshow(h);
            else
                stop(h);
            end
        end

        function ccw(h)
            result.response = -1;
            result.success = 1;
            if reshowStimulus
                reshow(h);
            else
                stop(h);
            end
        end
        
        function reshow(h)
            motion.setVisible(0);
            motion.setVisible(1, h.next);
            trigger.singleshot(atLeast('next', h.next + awaitInput - interval/2), @stop);
        end
        
        function abort(h)
            result.abort = 1;
            stop(h);
        end
        
        function failed(h)
            result.success = 0;
            stop(h)
        end
        
        function stop(h)
           motion.setVisible(0);
           fixation.setVisible(0);
           result.endTime = h.next;
           trigger.singleshot(atLeast('refresh', h.refresh+1), main.stop);
        end
    end
end