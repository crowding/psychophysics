function this = EyeCalibrationTrial(varargin)
    %attempt an automatic eye calibration.

    startTime = 0;
    onset = .0; %the onset of the saccade target.
    
    velocityThreshold = 40; %the velocity threshold for detecting a saccade.
    
    minLatency = .03; %the minimum latency (quite short!)
    maxLatency = .400; %the maximum latency for the saccade.
    saccadeMaxDuration = .100; %the max duration for the saccade.
    
    saccadeEndThreshold = 20; %when eye velocity drops below this, the saccade ends.
    settleTime = 0.1; %100 ms for settling
    
    absoluteWindow = 100; %the absolute fixation window...
    fixWindow = 2; %the window in which to maintain fixation...
    fixDuration = 1; %the minimum fixation time 
    
    targetX = 0;
    targetY = 0;
    targetRadius = 0.5;
    targetInnerRadius = 0.10;

    rewardDuration = 100;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    f1_ = figure(1); clf;
    %a1_ = axes();
    %f2_ = figure(2); clf;
    %a2_ = axes();
    
    function [params, result] = run(params)
        result = struct('target', [targetX targetY]);
        
        target = FilledDisk('loc', [targetX targetY], 'radius', targetRadius, 'color', [0 0 0], 'visible', 0);
        targetCenter = FilledDisk('loc', [targetX targetY], 'radius', targetInnerRadius, 'color', [0 0 0] + params.whiteIndex, 'visible', 0);
        
        trigger = Trigger();
        
        main = mainLoop...
            ( 'input', {params.input.keyboard, params.input.eyes}...
            , 'triggers', {EyeVelocityFilter(), trigger} ...
            , 'graphics', {target, targetCenter} ...
            );
        
        trigger.singleshot(atLeast('next', startTime), @begin);
        trigger.panic(keyIsDown('q'), @abort);

        %old = params.log;
        %params.log = @printf;
        params = main.go(params);
        
        plotTriggers(f1_, params, trigger);
        
        function begin(s)
            result.startTime = s.next;
            %set a watchdog timer...
            trigger.panic(atLeast('next', s.next + onset + maxLatency + saccadeMaxDuration + settleTime + fixDuration + rewardDuration/1000 + 1), @failed);

            %begin the trial...
            trigger.singleshot(atLeast('next', s.next + onset), @show);
        end
        
        onset_ = 0;
        function show(s)
            target.setVisible(1);
            targetCenter.setVisible(1);
            onset_ = s.next;
            params.input.eyes.eventCode(s.refresh, 0);
            trigger.first...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', velocityThreshold), @failed,  'eyeVt' ...
                , atLeast('eyeVt', s.next + minLatency), @awaitSaccade,                 'eyeVt' ...
                );
        end
        
        function awaitSaccade(s)
            trigger.first...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', velocityThreshold), @beginSaccade,      'eyeVt' ...
                , atLeast('eyeVt', s.triggerTime + maxLatency - minLatency), @failed, 'eyeVt' ...
                )
        end
        
        function beginSaccade(s)
            trigger.first...
                ( magnitudeAtMost('eyeVx', 'eyeVy', saccadeEndThreshold), @settle,  'eyeVt'  ...
                , atLeast('eyeVt', s.next + saccadeMaxDuration), @failedSaccade, 'eyeVt' ...
                );
        end
        
        settleTime_ = -1;
        function settle(s)
            settleTime_ = s.triggerTime;
            trigger.first...
                ( atLeast('eyeFt', s.triggerTime + settleTime), @fixate, 'eyeFt' ...
                );
        end
        
        function fixate(s)
            result.endpoint = [s.eyeFx(s.triggerIndex) s.eyeFy(s.triggerIndex)];
            trigger.first ...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', [s.eyeFx(s.triggerIndex);s.eyeFy(s.triggerIndex)], fixWindow), @failedRelative, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', [targetX;targetY], absoluteWindow), @failedAbsolute, 'eyeFt' ...
                , atLeast('eyeFt', settleTime_ + fixDuration), @success, 'eyeFt' ...
                );
        end
        
        function success(s)
            params.input.eyes.reward(s.refresh+1, rewardDuration);
            target.setVisible(0);
            targetCenter.setVisible(0);
            result.success = 1;
            result.endTime = s.next;
            trigger.singleshot(atLeast('next', s.next+rewardDuration/1000 + .200), main.stop);
        end
        
        function failedSaccade(s)
            failed(s);
        end

        function failedRelative(s)
            failed(s);
        end
        
        function failedAbsolute(s)
            failed(s);
        end

        function failed(s)
            target.setVisible(0);
            targetCenter.setVisible(0);
            result.success = 0;
            result.endTime = s.next;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
        function abort(s)
            target.setVisible(0);
            targetCenter.setVisible(0);
            result.success = 0;
            result.abort = 1;
            result.endTime = s.next();
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
    end
    
end
