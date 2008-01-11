function this = EyeCalibrationTrial(varargin)
    %attempt an automatic eye calibration.

    onset = .500; %the onset of the saccade target.
    
    maxLatency = .500; %the max latency for the saccade.
    
    velocityThreshold = 40; %the velocity threshold for detecting a saccade.
    
    saccadeMaxDuration = .300; %the max duration for the saccade.
    
    saccadeEndThreshold = 20;
    settleTime = 0.2;
    fixThreshold = 20; %the velocity threshold for duration.
    fixDuration = 0; %the minimum fixation time 
    
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
        %params.log = @printf;
        params = main.go(params);
        %params.log = old;

        function begin(s)
            trigger.singleshot(atLeast('next', s.next + onset), @show);
        end
        
        function show(s)
            target.setVisible(1);
            trigger.mutex...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', velocityThreshold), @beginSaccade ...
                , atLeast('next', s.next + saccadeMaxDuration), @failed ...
                );
        end
        
        function beginSaccade(s)
            trigger.mutex...
                ( magnitudeAtMost('eyeVx', 'eyeVy', saccadeEndThreshold), @settle ...
                , atLeast('next', s.next + maxLatency), @failed ...
                );
        end
        
        function settle(s)
            trigger.singleshot...
                ( atLeast('next', s.next + settleTime), @fixate ...
                );
        end
        
        function fixate(s)
            trigger.mutex ...
                ( magnitudeAtLeast('eyeVx', 'eyeVy', fixThreshold), @failed ...
                , atLeast('next', s.next + fixDuration), @success ...
                );
        end
        
        function success(s)
            target.setVisible(0);
            result.success = 1;
            params.input.eyes.reward(s.refresh, rewardDuration);
            trigger.singleshot(atLeast('next', s.next+rewardDuration + .100), main.stop);
            disp('success');
        end
        
        function failed(s)
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