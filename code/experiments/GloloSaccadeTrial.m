function this = GloloSaccadeTrial(varargin)
    %A trial for circular pursuit. The obzerver begins the trial by
    %fixating at a central fixation point. Another point comes up in a
    %circular trajectory; at some point it may change its color. 
    %The subject must wait until the central fixation point disappears,
    %then muce make a saccade to the moving object and pursue it for some
    %time.

    startTime = 0;
    fixation = FilledDisk('loc', [0 0], 'radius', 0.2, 'color', [0;0;0]);

    fixationLatency = 2; %how long to wait for acquiring fixation
    %If the target appears before then expect a saccade. Else just give a
    %reward.
    
    fixationStartWindow = 3; %this much radius for starting fixation
    fixationSettle = 0.0; %allow this long for settling fixation.
    fixationWindow = 1.5;
    fixationTime = 1; %the maximum fixation time. A reward will be given this long after beginning fixation.
    
    target = FilledDisk('loc', [8 0], 'radius', 0.2, 'color', 0);
    
    targetOnset = 1.0; %measured from beginning of fixation.
    targetBlank = 0.5; %after this much time on screen, the target will dim
    
    cueTime = Inf; %the saccade will be cued this long after 

    minLatency = 0.15;
    maxLatency = 0.5; %the eye needs to leave the fixation point at most this long after the cue.
    maxTransitTime = 0.1; %the eye needs to be in the target window this long after leaving the fixation window.
    saccadeSettleTime = 0.1; % allow hte eye to wander outside the window for this long before enforcing pursuit.
    
    targetWindow = 5; %radius of fixation window while saccading to and tracking target.
    targetFixationTime = 0.5; %how long the subject must track the target before reward.
    
    %here's the twist to this trial. You can specify a graphics object to use instead of a glolo.
    %It can be that instead of a spot you have to track a glolo.
    %This glolo is totally optional. If it is not used then the spot will
    %be used instead.
    trackingTarget = FilledDisk('loc', [8 0], 'radius', 0.2, 'color', 0);
    useTrackingTarget = 0;
    
    %as an added twist, you can show a precue. Combine this with multiple
    %tracking targets for a nice effect.
    precue = FilledDisk('loc', [8 0], 'radius', 0.2, 'color', 1);
    usePrecue = 0;
    precueOnset = 0;
    precueDuration = 0.25; %how long the precue is shown.
    
    errorTimeout = 1;
    earlySaccadeTimeout = 1;
    
    rewardSize = 100;
    rewardTargetBonus = 0.0; %ms reward per ms of tracking
    rewardLengthBonus = 0.0; %ms reward per ms of active trial
    
    extra = struct();

    plotOutcome = 1;
    
    persistent init__; %#ok
    this = autoobject(varargin{:});
        
    function [params, result] = run(params)
        color = @(c) c * (params.whiteIndex - params.blackIndex) + params.blackIndex;
        
        result = struct('success', NaN);
        
        trigger = Trigger();
        
        interval = params.cal.interval;

        trigger.panic(keyIsDown('q'), @abort);
        trigger.singleshot(atLeast('next', startTime), @begin);
        
        fixation.setVisible(0);
        target.setVisible(0);
        trackingTarget.setVisible(0);
        
        fixcolor = fixation.getColor();
        
        main = mainLoop ...
            ( 'input', {params.input.eyes, params.input.keyboard, EyeVelocityFilter()} ...
            , 'graphics', {fixation, target, trackingTarget, precue} ...
            , 'triggers', {trigger} ...
            );
        
        %EVENT HANDLERS
        
        function begin(k)
            fixation.setVisible(1, k.next);
            precue.setVisible(0);
            trigger.first ...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @settleFixation, 'eyeFt' ...
                , atLeast('eyeFt', k.next + fixationLatency), @failedWaitingFixation, 'eyeFt' ...
                );
        end
        
        function failedWaitingFixation(k)
            failed(k);
        end
        
        function settleFixation(k)
            trigger.first ...
                ( atLeast('eyeFt', k.triggerTime + fixationSettle), @fixate, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @failedSettling, 'eyeFt' ...
                );
        end
        
        function failedSettling(x)
            failed(x);
        end
        
        fixationOnset_ = 0;
        blinkhandle_ = -1;
        function fixate(k)
            %fixation time is how long you have to fixate for. Target onset
            %is measured after acquiring fixation. Cue time is how long
            %between target onset and when the cue shows.
            %If fixation time < target onset + cue time, then we reward for
            %maintaining fixation, else we reward for saccading to the target.
            %Also, if we reward fixation before target onset, don't show the precue?
            
            fixationOnset_ = k.triggerTime;
            if fixationTime < targetOnset + cueTime
                trigger.first ...
                    ( atLeast('eyeFt', fixationOnset_ + fixationTime), @success, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @failedFixation, 'eyeFt' ...
                    , atLeast('eyeFt', fixationOnset_ + targetOnset), @showTarget, 'eyeFt' ...
                    );
            else
                trigger.first ...
                    ( atLeast('eyeFt', fixationOnset_ + fixationTime), @success, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @failedFixation, 'eyeFt' ...
                    , atLeast('eyeFt', fixationOnset_ + targetOnset), @showTarget, 'eyeFt' ...
                    );
            end

            if usePrecue && precueOnset < fixationTime
                trigger.singleshot ...
                    ( atLeast('next', fixationOnset_ + precueOnset - interval/2), @showPrecue );
            end
            
            %from now on, blinks are not allowed. How to do this? It'd be
            %nice to have handles to the triggers! Ah.
            blinkhandle_ = trigger.singleshot ...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', [0;0], 40), @failedBlink);
        end
        
        function showPrecue(h)
            precue.setVisible(1, h.next);
            trigger.singleshot(atLeast('next', h.next + precueDuration - interval/2), @hidePrecue);
        end
        
        function hidePrecue(h)
            precue.setVisible(0);
        end
        
        function failedFixation(x)
            failed(x);
        end

        function failedBlink(x)
            failed(x);
        end
        
        blankhandle_ = -1;
        function showTarget(k) %#ok
            if useTrackingTarget
                trackingTarget.setVisible(1, k.next);
                target.setVisible(0, k.next); %note the second argument sets the 'onset'
            else
                target.setVisible(1, k.next);
            end
            
            if fixationTime < targetOnset + cueTime
                trigger.first ...
                    ( atLeast('eyeFt', fixationOnset_ + fixationTime), @success, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @failedEarly, 'eyeFt' ...
                    );
            else
                trigger.first ...
                    ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @failedEarly, 'eyeFt' ...
                    , atLeast('next', fixationOnset_ + targetOnset + cueTime), @hideFixation, 'next'...
                    );
            end
            
            blankhandle_ = trigger.singleshot(atLeast('next', fixationOnset_ + targetOnset + targetBlank), @blankTarget);
        end
        
        oldColor_ = [];
        function blankTarget(k) %#ok
            if useTrackingTarget
                trackingTarget.setVisible(0);
            else
                oldColor_ = target.getColor();
                target.setVisible(0); %(color(targetBlankColor));
            end
        end

        function hideFixation(k)
            fixation.setVisible(0);
            %to reduce latency, trigger on the UNfiltered eye position
            %(window centered around the current position).
            trigger.first...
                ( circularWindowExit('eyeX', 'eyeY', 'eyeT', [k.x;k.y], fixationWindow), @failedEarly, 'eyeT' ...
                , atLeast('eyeT', k.next + minLatency), @awaitSaccade, 'eyeT' ...
                );
        end
        
        function awaitSaccade(k)
            trigger.first...
                ( circularWindowExit('eyeX', 'eyeY', 'eyeT', [k.x;k.y], fixationWindow), @unblankTarget, 'eyeT' ...
                , atLeast('eyeT', k.triggerTime + maxLatency - minLatency), @failedSaccade, 'eyeT' ...
                );            
        end

        function failedSaccade(x)
            failed(x);
        end

        function failedEarly(x)
            trigger.remove([blinkhandle_ blankhandle_]);
            target.setVisible(0);
            fixation.setVisible(1);
            fixation.setColor([255;0;0]);
            trackingTarget.setVisible(0);
            trigger.singleshot(atLeast('next', x.next + earlySaccadeTimeout), @failed);
        end
        
        function unblankTarget(k)
            %only getting to this point are we willing to say "success"
            %unless failure obtains
            result.success = 1; %PENDING....
            if (useTrackingTarget)
                trackingTarget.setVisible(0);
                target.setVisible(1);
            else
                %target.setColor(oldColor_);
            end
            
            trigger.remove(blankhandle_);
            trigger.first ...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', target.getLoc, targetWindow), @settleSaccade, 'eyeFt'...
                , atLeast('eyeFt', k.triggerTime + maxTransitTime), @failedAcquisition, 'eyeFt' ...
                );
        end
        
        function failedAcquisition(x)
            result.success = 0; %whoops
            failed(x);
        end
        
        function settleSaccade(k)
            trigger.first...
                ( atLeast('eyeFt', k.triggerTime + saccadeSettleTime), @fixateTarget, 'eyeFt'...
                );
        end

        function fixateTarget(k)
            trigger.remove(blankhandle_);
            trigger.first...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', target.getLoc, targetWindow), @failedPursuit, 'eyeFt'...
                , atLeast('eyeFt', k.triggerTime + targetFixationTime - saccadeSettleTime), @success, 'eyeFt'...
                );
        end
        
        function failedPursuit(x)
            result.success = 0;
            failed(x);
        end
            
        function success(k)
            target.setVisible(0);
            trackingTarget.setVisible(0);
            trigger.remove([blinkhandle_ blankhandle_]);

            %reward size. give a bonus based on how long the trial was.
            bonus = rewardLengthBonus * (k.triggerTime - fixationOnset_) ;
            if fixationTime > targetOnset + cueTime
                bonus = bonus + rewardTargetBonus*targetFixationTime;
            end
            
            rs = floor(rewardSize + 1000 * bonus) %#ok
            [rewardAt, when] = params.input.eyes.reward(k.refresh, rs);
            trigger.singleshot(atLeast('next', when + rs/1000 + 0.1), @endTrial);
        end
        
        function failed(k)
            trigger.remove([blinkhandle_ blankhandle_]);
            fixation.setVisible(0);
            target.setVisible(0);
            precue.setVisible(0);
            trackingTarget.setVisible(0);
            
            trigger.singleshot(atLeast('next', k.next + errorTimeout), @endTrial);
        end
        
        function abort(k)
            result.success = NaN;
            result.abort = 1;
            trigger.singleshot(atLeast('refresh', k.refresh+1), @endTrial);
            result.endTime = k.next();
        end
        
        function endTrial(k)
            fixation.setVisible(0);
            target.setVisible(0);
            trackingTarget.setVisible(0);
            fixation.setColor(fixcolor);
            
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
            result.endTime = k.next();
        end
        
        %END EVENT HANDLERS
        params = main.go(params);

        if plotOutcome && isfield(params, 'uihandles') && ~isempty(params.uihandles)
            plotTriggers(params.uihandles.trial_axes, params, trigger);
        end
    end
end