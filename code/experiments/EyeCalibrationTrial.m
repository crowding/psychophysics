function this = EyeCalibrationTrial(varargin)
    %attempt an automatic eye calibration.

    startTime = 0;
    onset = .0; %the onset of the saccade target.
    
    velocityThreshold = 40; %the velocity threshold for detecting a saccade.
    
    minLatency = .100; %the minimum saccade latency (defined by velocity threshold crossing)
    maxLatency = .300; %the maximum latency for the saccade.
    saccadeMaxDuration = .100; %the max duration for the saccade.
    
    saccadeEndThreshold = 20; %when eye velocity drops below this, the saccade ends.
    settleTime = 0.1; %100 ms for settling
    
    absoluteWindow = 100; %the absolute fixation window...
    fixWindow = 2; %the window in which to maintain fixation...
    fixDuration = 1; %the minimum fixation time 
    
    targetX = 0; %where the target appears
    targetY = 0; %where the target appears
    targetRadius = 0.2; %the outer dark ring
    targetInnerRadius = 0.10; %the inner white spot

    rewardDuration = 100; %duration of the reward.
    plotOutcome = 1;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    
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
        trigger.panic(keyIsDown({'LeftControl', 'ESCAPE'}), @abort);

        params = main.go(params);
        
        if plotOutcome && isfield(params, 'uihandles') && ~isempty(params.uihandles)
            plotTriggers(params.uihandles.trial_axes, params, trigger);
        end
        
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
            %use 'first' to calture the time coordinate of the threshold
            %crossing.
            trigger.first...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', velocityThreshold), @beginSaccade,  'eyeVt' ...
                , atLeast('eyeVt', s.next + maxLatency), @failedSaccade, 'eyeVt' ...
                );
        end
        
        function beginSaccade(s)
            t = GetSecs();
            et = Eyelink('TrackerTime');
            [el, raw] = Eyelink('NewestFloatSampleRaw');
            etm = et - getclockoffset(params, 100)/1000;
            fprintf(2, 'lat = %g next-t = %g next-eyeT=%g t-eyeT=%g\n', s.triggerTime - onset_, s.next-t, s.next-s.eyeT(end), t-s.eyeT(end));
            if (s.triggerTime - onset_ < minLatency)
                %saccade was too early. Fail out on next refresh.

                trigger.singleshot(atLeast('refresh', s.refresh + 1), @failedEarly);
            else
                %wait for the end of the saccade...
                trigger.first...
                    ( magnitudeAtMost('eyeVx', 'eyeVy', saccadeEndThreshold), @settle,  'eyeVt'  ...
                    , atLeast('eyeVt', s.next + saccadeMaxDuration), @failedSaccade, 'eyeVt' ...
                    );
            end
        end
        
        settleTime_ = -1;
        function settle(s)
            settleTime_ = s.triggerTime;
            trigger.first...
                ( atLeast('eyeFt', s.triggerTime + settleTime), @fixate, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', [s.eyeFx(s.triggerIndex);s.eyeFy(s.triggerIndex)], fixWindow), @failedSettle, 'eyeFt' ...
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
        
        function failedEarly(s)
            failed(s);
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

        function failedSettle(s)
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
