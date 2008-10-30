function this = SimpleSaccadeTrial(varargin)
    %A trial for circular pursuit. The obzerver begins the trial by
    %fixating at a central fixation point. Another point comes up in a
    %circular trajectory; at some point it may change its color. 
    %The subject must wait until the central fixation point disappears,
    %then muce make a saccade to the moving object and pursue it for some
    %time.

    fixationOnset = 0.5; %measured from 'begin'
    fixationPointLoc = [0 0];
    fixationPointSize = 0.2;
    fixationPointColor = 0;
    fixationLatency = 2; %how long to wait for acquiring fixation
    %If the target appears before then expect a saccade. Else just give a
    %reward.
    
    fixationStartWindow = 3; %this much radius for starting fixation
    fixationSettle = 0.0; %allow this long for settling fixation.
    fixationWindow = 1.5;
    fixationTime = 1; %the maximum fixation time.
    
    targetOnset = 1.0; %measured from beginning of fixation.
    targetSize = 0.2;
    targetLoc = [8 0]; %the location of the target...
    targetColor = 0; %the color of the target...
    targetBlank = 0.5; %after this much time on screen, the target will dim
    targetBlankColor = 0.75; %the target will dim to this color
    
    cueTime = Inf; %the saccade will be cued at the end of the fixationTime, or at this time after target onset, whichever is first.

    maxLatency = 0.5; %you need to leave the fixaiton point at most this long after the cue
    maxTransitTime = 0.1; %you need to be on top of the target this long after leaving the fixation window

    targetWindow = 5;
    targetFixationTime = 0.5;
    
    %here's the twist to this trial. You can specify a graphics object to use instead of a glolo.
    %It can be that instead of a spot you have to track a glolo.
    %This glolo is totally optional. If it is not used then the spot will
    %be used instead.
    useTrackingTarget = 0;
    trackingTarget = [];
    
    errorTimeout = 1;
    
    rewardSize = 100;
    rewardTargetBonus = 0.0; %ms reward per ms of tracking
    
    plotOutcome = 1;
    plotAxes = [];

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    if isempty(plotAxes) && plotOutcome
        figure();
        plotAxes = axes();
    end
    
    function setTargetRadius(r)
        %required for backwards compatibility
        targetLoc = targetLoc / norm(targetLoc) * r;
    end

    function setTargetPhase(w)
        %required for backwards compatibility
        targetLoc = norm(targetLoc) * [cos(w) -sin(w)];
    end
    
    function [params, result] = run(params)
        onset_ = 0;

        color = @(c) c * (params.whiteIndex - params.blackIndex) + params.blackIndex;
        
        result = struct('success', NaN);
        fix = FilledDisk('loc', fixationPointLoc, 'radius', fixationPointSize, 'color', color(fixationPointColor));
        targ = FilledDisk('loc', targetLoc, 'radius', targetSize, 'color', color(targetColor));
        
        trigger = Trigger();

        trigger.panic(keyIsDown('q'), @abort);
        trigger.singleshot(atLeast('refresh', 0), @begin);
        
        main = mainLoop ...
            ( 'input', {params.input.eyes, params.input.keyboard, EyeVelocityFilter()} ...
            , 'graphics', {fix, targ} ...
            , 'triggers', {trigger} ...
            );
        
        %EVENT HANDLERS
        
        function begin(k)
            trigger.singleshot(atLeast('next', k.next + fixationOnset), @showFixationPoint);
        end
        
        function showFixationPoint(k)
            onset_ = k.next;
            fix.setVisible(1);
            trigger.first ...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationStartWindow), @settleFixation, 'eyeFt' ...
                , atLeast('eyeFt', k.next + fixationLatency), @failed, 'eyeFt' ...
                );
        end
        
        function settleFixation(k)
            trigger.first ...
                ( atLeast('eyeFt', k.triggerTime + fixationSettle), @fixate, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationStartWindow), @failed, 'eyeFt' ...
                );
        end
        
        fixationOnset_ = 0;
        blinkhandle_ = -1;
        function fixate(k)
            fixationOnset_ = k.triggerTime;
            if fixationTime < targetOnset
                trigger.first ...
                    ( atLeast('eyeFt', fixationOnset_ + fixationTime), @success, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @failed, 'eyeFt' ...
                    );
            else
                trigger.first ...
                    ( atLeast('eyeFt', fixationOnset_ + targetOnset), @showTarget, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @failed, 'eyeFt' ...
                    );
            end
            
            %from now on, blinks are not allowed. How to do this? It'd be
            %nice to have handles to the triggers! Ah.
            blinkhandle_ = trigger.singleshot ...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', [0;0], 40), @failed);
        end
        
        blankhandle_ = -1;
        function showTarget(k) %#ok
            targ.setVisible(1);
            t = min(fixationTime - targetOnset, cueTime); %time from target onset to cue
            blankhandle_ = trigger.singleshot(atLeast('next', fixationOnset_ + targetOnset + targetBlank), @blankTarget);
            trigger.first ...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @failed, 'eyeFt'...
                , atLeast('next', fixationOnset_ + targetOnset + t), @hideFixation, 'next'...
                );
        end
        
        function blankTarget(k) %#ok
            targ.setColor(color(targetBlankColor));
        end

        function hideFixation(k)
            fix.setVisible(0);
            result.success = 0; %only at this point are we willing to say "failed" until success obtains
            
            trigger.first...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @unblankTarget, 'eyeFt' ...
                , atLeast('eyeFt', k.next + maxLatency), @failed, 'eyeFt' ...
                );
        end
        
        function unblankTarget(k)
            targ.setColor(color(targetColor));
            trigger.remove(blankhandle_);
            trigger.first ...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', targ.getLoc(), targetWindow), @fixateTarget, 'eyeFt'...
                , atLeast('eyeFt', k.triggerTime + maxTransitTime), @failed, 'eyeFt' ...
                );
        end
        
        function fixateTarget(k)
            trigger.remove(blankhandle_);
            trigger.first...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', targ.getLoc(), targetWindow), @failed, 'eyeFt'...
                , atLeast('eyeFt', k.triggerTime + targetFixationTime), @success, 'eyeFt'...
                );
        end
            
        function success(k)
            result.success = 1;
            fix.setVisible(0);
            trigger.remove([blinkhandle_ blankhandle_]);

            %reward size
            rs = floor(rewardSize + 1000 * rewardTargetBonus * targetFixationTime) %#ok
            [rewardAt, when] = params.input.eyes.reward(k.refresh, rs);
            trigger.singleshot(atLeast('next', when + rs/1000 + 0.1), @endTrial);
        end
        
        function failed(k)
            trigger.remove([blinkhandle_ blankhandle_]);
            fix.setVisible(0);
            targ.setVisible(0);
            targ.setColor(params.backgroundIndex); %hack, in case it shows...
            
            trigger.singleshot(atLeast('next', k.next + errorTimeout), @endTrial);
        end
        
        function abort(k)
            result.success = NaN;
            result.abort = 1;
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
        end
        
        function endTrial(k)
            fix.setVisible(0);
            targ.setVisible(0);
            
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
        end
        
        %END EVENT HANDLERS
        params = main.go(params);
        
        if plotOutcome
            plotTriggers(plotAxes, params, trigger);
        end
    end
end
    
    