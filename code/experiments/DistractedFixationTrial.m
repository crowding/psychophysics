function this = DistractedFixationTrial(varargin)

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
    
    f1_ = figure(1); clf;
    a1_ = axes();

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        onset_ = 0;

        color = @(c) c * (params.whiteIndex - params.blackIndex) + params.blackIndex;
        
        result = struct('success', 0);
        fix = FilledDisk('loc', fixationPointLoc, 'radius', fixationPointSize, 'color', color(fixationPointColor));
        dist = FilledDisk('loc', fixationPointLoc + [cos(distractorPhase), -sin(distractorPhase)]*distractorRadius, 'radius', distractorSize, 'color', color(distractorColor));
        
        trigger = Trigger();

        trigger.panic(keyIsDown('q'), @abort);
        trigger.singleshot(atLeast('refresh', 0), @begin);
        
        main = mainLoop ...
            ( 'input', {params.input.eyes, params.input.keyboard, EyeVelocityFilter()} ...
            , 'graphics', {fix, dist} ...
            , 'triggers', {trigger} ...
            );
        
        params = main.go(params);
        
        
        function begin(k)
            trigger.singleshot(atLeast('next', k.next + fixationOnset), @showFixationPoint);
        end
        
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
        
        d = params.input.eyes.getData();
        d([1 2],:) = repmat(params.input.eyes.getOffset(), 1, size(d,2)) + params.input.eyes.getSlope() * d([1 2],:);
        e = trigger.getEvents();
        
        axes(a1_); cla
        hold on;
        
        %x- any y- locations of the trace
        plot(d(3,:) - onset_, d(1,:), 'r-', d(3,:) - onset_, d(2,:), 'b-');
        plot(0, fixationPointLoc(1), 'ro', 0, fixationPointLoc(2), 'bo')
        plot(distractorOnset, fixationPointLoc(1) + cos(distractorPhase) * distractorRadius, 'rx', distractorOnset, fixationPointLoc(2) - sin(distractorPhase) * distractorRadius, 'bx')
        ylim([-15 15]);
        
        %draw labels...
        %what height should we draw text at
        labels = regexprep(e(:,2), '.*/', '');
        times = [e{:,1}]' - onset_;
        heights = interp1(d(3,~isnan(d(1,:))) - onset_, max(d(1,~isnan(d(1,:))), d(2,~isnan(d(1,:)))), times, 'linear', 'extrap');
        t = text(times, heights+1, labels, 'rotation', 90);

        %make sure the graph is big enough to hold the labels
        %this doesn't deal well with rotation.../
%        xs = get(t, 'Extent');
%        mn = min(cat(1,xs{:}));
%        mx = max(cat(1,xs{:}));
%        ylim([min(-15, mn(2)) max(15, mx(2) + mx(4))]);
        hold off;
    end
end
    
    