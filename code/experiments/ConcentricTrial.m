%In this trial, the subect fixates at the central point, a motion occurs,
%and the subject has to respont by turning the knob let or right. Pretty
%simple...

function this = ConcentricTrial(varargin)

    startTime = 0;
    knobTurnThreshold = 3;
    awaitInput = 0.5; %how early to accept a response from the subject. Fixation is also enforced up until this time.
    maxResponseLatency = Inf; %how long to wait for the response (measured after awaitInput)
    lateTimeout = 1;
    earlyTimeout = 1;
    
    fixation = FilledDisk([0, 0], 0.1, [0 0 0]);
    
    audioCueTimes = []; %when to play an audio cue, relative to motion onset.
   
    requireFixation = 1;
    fixationLatency = 2; %how long to wait for acquiring fixation
    
    fixationStartWindow = 3; %this much radius for starting fixation
    fixationSettle = 0.3; %allow this long for settling fixation.
    fixationWindow = 1.5; %subject must fixate this closely...
    reshowStimulus = 0; %whether to reshow the stimulus after the response (for training purposes)
    beepFeedback = 0; %whether to give a tone for feedback...
    desiredResponse = 0; %which response (1 = cw) is correct, if feedback is desired.
    feedbackFailedFixation = 0;
    
    motion = CauchySpritePlayer...
        ( 'process', CircularCauchyMotion ...
            ( 'x', 0 ...
            , 'y', 0 ...
            , 'radius', 15 ...
            , 'dphase', 1/15 ...
        ) ...
    );
    
    occluders={};
    useOccluders = 0;

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

        %in any case, log all the knob rotations
        trigger.multishot(nonZero('knobRotation'), @knobRotated);

        motionStarted_ = Inf;
        motion.setVisible(0);
        fixation.setVisible(0);
        for i = occluders(:)'
            i{1}.setVisible(0);
        end
        
        if requireFixation && (beepFeedback || ~isempty(audioCueTimes))
            main = mainLoop ...
                ( 'input', {params.input.eyes, params.input.audioout, params.input.keyboard, params.input.knob, EyeVelocityFilter()} ...
                , 'graphics', {fixation, motion, occluders{:}} ...
                , 'triggers', {trigger} ...
                );
        elseif requireFixation
            main = mainLoop ...
                ( 'input', {params.input.eyes, params.input.keyboard, params.input.knob, EyeVelocityFilter()} ...
                , 'graphics', {fixation, motion, occluders{:}} ...
                , 'triggers', {trigger} ...
                );
        elseif (beepFeedback || ~isempty(audioCueTimes))
            main = mainLoop ...
                ( 'input', {params.input.audioout, params.input.keyboard, params.input.knob} ...
                , 'graphics', {fixation, motion, occluders{:}} ...
                , 'triggers', {trigger} ...
                );
        else
            main = mainLoop ...
                ( 'input', {params.input.keyboard, params.input.knob} ...
                , 'graphics', {fixation, motion, occluders{:}} ...
                , 'triggers', {trigger} ...
                );
        end
        
        main.go(params);
        
        function knobRotated(h)
            %do nothing, just log the event.
        end
                
        function awaitFixation(h)
            fixation.setVisible(1);
            if useOccluders
                for i = occluders(:)'
                    i{1}.setVisible(1);
                end
            end
            trigger.first ...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @settleFixation, 'eyeFt' ...
                , atLeast('eyeFt', h.next + fixationLatency), @failedWaitingFixation, 'eyeFt' ...
                );
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
        
        responseCollectionHandle_ = [];
        function startMotion(h)
            fixation.setVisible(1);
            motion.setVisible(1, h.next);
            if useOccluders
                for i = occluders(:)'
                    i{1}.setVisible(1);
                end
            end
            
            for i = audioCueTimes(:)'
                %set the cues to play at the presice times relative to
                %simulus onset.
                audio.play('cue', h.next + i);
            end

            motionStarted_ = h.next;
            if requireFixation
                trigger.first...
                    ( atLeast('eyeFt', h.next + awaitInput), @endFixationPeriod, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @failedFixation, 'eyeFt' ...
                    );
            end
            %respond to input from the beginning of every trial...
            responseCollectionHandle_ = trigger.first...
                ( atLeast('knobPosition', h.knobPosition+knobTurnThreshold), @cw, 'knobTime' ...
                , atMost('knobPosition', h.knobPosition-knobTurnThreshold), @ccw, 'knobTime' ...
                , atLeast('knobDown', 1), @failed, 'knobTime' ... 
                );
        end
        
        function endFixationPeriod(h)
            %do nothing;;;
        end
        
        function failedFixation(h)
            if feedbackFailedFixation
                %flash the fix point as feedback.
                fixationFlashOff(h);
                trigger.singleshot(atLeast('next', h.next + 0.25), @fixationFlashOn);
                trigger.singleshot(atLeast('next', h.next + 0.50), @fixationFlashOff);
                trigger.singleshot(atLeast('next', h.next + 0.75), @fixationFlashOn);
                trigger.singleshot(atLeast('next', h.next + 1.00), @fixationFlashOff);
                trigger.singleshot(atLeast('next', h.next + 1.00), @failed);
                trigger.remove(responseCollectionHandle_);
                fprintf(2, '>>>> broke fixation\n');
            else
                failed(h)
            end
        end
        
        function fixationFlashOn(h)
            fixation.setVisible(1);
        end
        
        function fixationFlashOff(h)
            fixation.setVisible(0);
        end
        
        function cw(h)
            result.response = 1;
            responseCollected(h);
        end

        function ccw(h)
            result.response = -1;
            responseCollected(h);
        end

        function responseCollected(h)
            result.success = 1;
            %start something else, based on the response
            if h.knobTime - awaitInput < motionStarted_;
                trigger.singleshot(atLeast('refresh',h.refresh+1), @tooShort);
            elseif h.knobTime - motionStarted_ - awaitInput > maxResponseLatency
                trigger.singleshot(atLeast('refresh',h.refresh+1), @tooLong);
            elseif reshowStimulus
                trigger.singleshot(atLeast('refresh',h.refresh+1), @reshow);
            elseif beepFeedback
                if result.response == desiredResponse
                    %make a beep
                    params.input.audio.play('ding');
                    trigger.singleshot(atLeast('next',h.next+0.2), @stop);
                else
                    trigger.singleshot(atLeast('refresh',h.refresh+1), @stop);
                end
            else
                trigger.singleshot(atLeast('refresh',h.refresh+1), @stop);
            end
        end
        
        function tooLong(h)
            %turn the fixation point red as feedback.
            result.success = 0;
            fixation.setColor([255 0 0]);
            trigger.singleshot(atLeast('next', h.next + lateTimeout), @stop);
            fprintf(2, '>>>> too slow\n');
        end
        
        function tooShort(h)
            %turn the fixation point blue as feedback.
            result.success = 0;
            fixation.setColor([0 0 255]);
            trigger.singleshot(atLeast('next', h.next + earlyTimeout), @stop);
            fprintf(2, '>>>> too fast\n');
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
            stop(h);
        end
        
        function stop(h)
           motion.setVisible(0);
           fixation.setVisible(0);
           fixation.setColor([0 0 0]);
           if useOccluders
               for i = occluders(:)'
                   i{1}.setVisible(0, h.next);
               end
           end
           result.endTime = h.next;
           trigger.singleshot(atLeast('refresh', h.refresh+1), main.stop);
        end
    end
end