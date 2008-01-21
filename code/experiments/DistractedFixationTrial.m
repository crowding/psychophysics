function this = DistractedFixationTrial(varargin)

    onset = 0;

    fixationPointLoc = [0 0];
    fixationPointSize = 0.2;
    fixationPointColor = 0;
    distractorSize = 1;
    distractorRadius = 8;
    distractorPhase = 0;
    distractorColor = 0.4;
    
    fixationOnset = 0.5;
    maxLatency = 0.5;
    distractorOnset = 1.0;
    distractorDuration = 0.3;
    fixationWindow = 3;
    fixationTime = 1;
    
    errorTimeout = 1;
    
    rewardSize = 100;
    
    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        color = @(c) c * (params.whiteIndex - params.blackIndex) + params.blackIndex;
        
        result = struct('success', 0);
        fix = FilledDisk('loc', fixationPointLoc, 'radius', fixationPointSize, 'color', color(fixationPointColor));
        dist = FilledDisk('loc', fixationPointLoc + [cos(distractorPhase), -sin(distractorPhase)]*distractorRadius, 'radius', distractorSize, 'color', color(distractorColor));
        
        trigger = Trigger();

        trigger.panic(keyIsDown('q'), @abort);
        trigger.singleshot(atLeast('refresh', 0), @begin);
        
        main = mainLoop ...
            ( 'input', {params.input.eyes, params.input.keyboard, eyeVelocityFilter()} ...
            , 'graphics', {fix, dist} ...
            , 'triggers', {trigger} ...
            );
        
        params = main.go(params);
        
        
        function begin(k)
            trigger.singleshot(atLeast('next', k.next + fixationOnset), @showFixationPoint);
        end
        
        onset_ = 0;
        function showFixationPoint(k)
            onset_ = k.next;
            fix.setVisible(1);
            trigger.singleshot...
                ( atLeast('next', onset_ + distractorOnset), @showDistractor ...
                );
            trigger.first ...
                ( atLeast('eyeFt', k.next + maxLatency), @failed, 'eyeFt' ...
                , circularWindowEnter('eyeFx', 'eyeFy', fixationPointLoc, fixationWindow), @fixate, 'eyeFt' ...
                );
        end
        
        function fixate(k)
            trigger.first ...
                ( atLeast('eyeFt', onset_ + maxLatency + fixationTime), @success, 'eyeFt' ...
                , circularWindowExit('eyeFx', 'eyeFy', fixationPointLoc, fixationWindow), @failed, 'eyeFt' ...
                );
        end
        
        function showDistractor(k)
            dist.setVisible(1);
            trigger.singleshot...
                ( atLeast('next', onset_ + distractorOnset + distractorDuration), @hideDistractor ...
                );
        end
        
        function hideDistractor(k)
            dist.setVisible(0);
        end
            
        function success(k)
            fix.setVisible(0);
            [rewardAt, when] = params.input.eyes.reward(k.refresh, rewardSize);
            trigger.singleshot(atLeast('next', when + rewardSize/1000 + 0.1), @endTrial);
        end

        function endTrial(k)
            fix.setVisible(0);
            dist.setVisible(0);
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
        end

        function failed(k)
            result.success = 0;
            
            fix.setVisible(0);
            dist.setVisible(0);
            dist.setColor(color(0.5)); %hack, in case it shows...
            
            trigger.singleshot(atLeast('next', k.next + errorTimeout), @endTrial);
        end
        
        function abort(k)
            result.success = 0;
            result.abort = 1;
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
        end
    end
end
    
    