function this = SimpleSaccadeTrial(varargin)

    fixationOnset = 0.5; %measured from 'begin'
    fixationPointLoc = [0 0];
    fixationPointSize = 0.2;
    fixationPointColor = 0;
    
    fixationWindow = 3;
    fixationTime = 1; %the maximum fixation time.
    %If the target appears before then expect a saccade. Else just give a reward.
    
    targetSize = 0.2;
    targetLoc = [8 0]; %the location of the target...
    targetColor = 0; %the color of the target...
    
    maxLatency = 0.5;
    targetOnset = 1.0; %measured from onset fo fixation...
     
    targetFixationTime = 0.5;
    
    errorTimeout = 2;
    
    rewardSize = 200;
    
    f1_ = figure(1); clf;
    a1_ = axes();

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
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
        
        result = struct('success', 0);
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
        
        params = main.go(params);
        
        %EVENT HANDLERS
        
        function begin(k)
            trigger.singleshot(atLeast('next', k.next + fixationOnset), @showFixationPoint);
        end
        
        function showFixationPoint(k)
            onset_ = k.next;
            fix.setVisible(1);
            trigger.first ...
                ( atLeast('eyeFt', k.next + maxLatency), @failed, 'eyeFt' ...
                , circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @fixate, 'eyeFt' ...
                );
        end
        
        function fixate(k)
            if fixationTime < targetOnset
                trigger.first ...
                    ( atLeast('eyeFt', k.triggerTime + fixationTime), @success, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @failed, 'eyeFt' ...
                    );
            else
                trigger.first ...
                    ( atLeast('eyeFt', k.triggerTime + targetOnset), @showTarget, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @failed, 'eyeFt' ...
                    );
            end
        end
        
        function showTarget(k)
            targ.setVisible(1);
            trigger.first ...
                ( circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fix.getLoc(), fixationWindow), @failed, 'eyeFt'...
                , atLeast('next', onset_ + fixationTime), @hideFixation, 'next'...
                );
        end
        
        function hideFixation(k)
            fix.setVisible(0);
            
            trigger.first...
                ( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', targ.getLoc(), fixationWindow), @fixateTarget, 'eyeFt'...
                , atLeast('eyeFt', k.next + maxLatency), @failed, 'eyeFt' ...
                );
        end
        
        function fixateTarget(k)
            trigger.first...
                ( circularWindowExit('eyeFx', 'eyeFy', targ.getLoc(), fixationWindow), @failed, 'eyeFt'...
                , atLeast('eyeFt', k.triggerTime + targetFixationTime), @success, 'eyeFt'...
                );
        end
            
        function success(k)
            fix.setVisible(0);
            [rewardAt, when] = params.input.eyes.reward(k.refresh, rewardSize);
            trigger.singleshot(atLeast('next', when + rewardSize/1000 + 0.1), @endTrial);
        end
        
        function failed(k)
            result.success = 0;
            
            fix.setVisible(0);
            targ.setVisible(0);
            targ.setColor(color(0.5)); %hack, in case it shows...
            
            trigger.singleshot(atLeast('next', k.next + errorTimeout), @endTrial);
        end
        
        function abort(k)
            result.success = 0;
            result.abort = 1;
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
        end
        
        function endTrial(k)
            fix.setVisible(0);
            targ.setVisible(0);
            trigger.singleshot(atLeast('refresh', k.refresh+1), main.stop);
        end
        
        %END
        
        d = params.input.eyes.getData();
        d([1 2],:) = repmat(params.input.eyes.getOffset(), 1, size(d,2)) + params.input.eyes.getSlope() * d([1 2],:);
        e = trigger.getEvents();
        
        axes(a1_); cla
        hold on;
        
        %x- any y- locations of the trace
        plot(d(3,:) - onset_, d(1,:), 'r-', d(3,:) - onset_, d(2,:), 'b-');
        plot(0, fixationPointLoc(1), 'ro', 0, fixationPointLoc(2), 'bo')
%        plot(targetOnset, fixationPointLoc(1) + cos(targetPhase) * targetRadius, 'rx', targetOnset, fixationPointLoc(2) - sin(targetPhase) * targetRadius, 'bx')
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
    
    