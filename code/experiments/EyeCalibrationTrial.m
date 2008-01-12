function this = EyeCalibrationTrial(varargin)
    %attempt an automatic eye calibration.

    onset = .500; %the onset of the saccade target.
    
    velocityThreshold = 40; %the velocity threshold for detecting a saccade.
    
    minLatency = .150; %the minimum latency 
    maxLatency = .400; %the maximum latency for the saccade.
    saccadeMaxDuration = .200; %the max duration for the saccade.
    
    saccadeEndThreshold = 20; %when eye velocity drops below this, the saccade ends.
    settleTime = 0.1;
    
    fixWindow = 5; %the window in which to maintain fixation...
    fixDuration = .30; %the minimum fixation time 
    
    targetX = [0];
    targetY = [0];
    targetRadius = 0.5;

    rewardDuration = 100;
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = struct();
        
        target = FilledDisk('loc', [targetX targetY], 'radius', targetRadius, 'color', [0 0 0], 'visible', 0);
        
        trigger = Trigger();
        
        main = mainLoop...
            ( 'input', {params.input.keyboard, params.input.eyes}...
            , 'triggers', {EyeVelocityFilter(), trigger} ...
            , 'graphics', {target} ...
            );
        
        trigger.singleshot(atLeast('refresh', 1), @begin);
        trigger.panic(keyIsDown('q'), @abort);

        old = params.log;
        params.log = @printf;
        params = main.go(params);
        params.log = old;

        function begin(s)
            %set a watchdog timer...
            trigger.panic(atLeast('next', s.next + maxLatency + saccadeMaxDuration + settleTime + fixDuration + rewardDuration/1000 + 1, 'next'), @failedWatchdog);
            
            %begin the trial...
            trigger.singleshot(atLeast('next', s.next + onset), @show);
        end
        
        function show(s)
            target.setVisible(1);
            params.input.eyes.eventCode(s.refresh, 0);
            trigger.mutex...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', velocityThreshold), @failedBegin ...
                , atLeast('next', s.next + minLatency), @awaitSaccade ...
                );
        end
        
        function awaitSaccade(s)
            trigger.mutex...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', velocityThreshold), @beginSaccade ...
                , atLeast('next', s.next + maxLatency - minLatency), @failedSaccade ...
                )
        end
        
        function beginSaccade(s)
            trigger.mutex...
                ( magnitudeAtMost('eyeVx', 'eyeVy', 'eyeVt', saccadeEndThreshold), @settle ...
                , atLeast('next', s.next + saccadeMaxDuration), @failedEndSaccade ...
                );
        end
        
        function settle(s)
            trigger.singleshot...
                ( atLeast('eyeFt', s.triggerTime + settleTime, 'eyeFt'), @fixate ...
                );
        end
        
        function fixate(s)
            try
            trigger.mutex ...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', [s.x s.y], fixWindow), @failedFixate ...
                , atLeast('eyeFt', s.triggerTime + fixDuration, 'eyeFt'), @success ...
                );
            catch
                rethrow(lasterror);
            end
        end
        
        function success(s)
            params.input.eyes.reward(s.refresh, rewardDuration);
            target.setVisible(0);
            result.success = 1;
            trigger.singleshot(atLeast('next', s.next+rewardDuration/1000 + .100), main.stop);
            disp('success');
        end

        function failedWatchdog(s)
            disp failedWatchdog
            target.setVisible(0);
            result.success = 0;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end

        function failedBegin(s)
            disp failedBegin
            target.setVisible(0);
            result.success = 0;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
        function failedFixate(s)
            disp failedFixate
            target.setVisible(0);
            result.success = 0;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
        function failedEndSaccade(s)
            disp failedEndSaccade
            target.setVisible(0);
            result.success = 0;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
        function failedSaccade(s)
            disp failedSaccade
            target.setVisible(0);
            result.success = 0;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
        function abort(s)
            target.setVisible(0);
            result.abort = 1;
            trigger.singleshot(atLeast('refresh', s.refresh+1), main.stop);
        end
        
    end
    
end