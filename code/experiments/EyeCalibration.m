function e = EyeCalibration(varargin)

    e = Experiment(varargin{:});
    e.trials.base = EyeCalibrationTrial();
    e.trials.base.absoluteWindow = 5;
    e.trials.base.maxLatency = 0.5;
    e.trials.base.fixDuration = 1.0;
    e.trials.base.fixWindow = 2.5;
    e.trials.base.rewardDuration = 200;
    e.trials.base.settleTime = 0.2;
    e.trials.base.targetRadius = 0.2;

    e.trials.add('targetY', linspace(-10, 10, 9));
    e.trials.add('targetX', linspace(-10, 10, 9));
%    e.trials.add({'targetX', 'targetY'}, {{-10 0} {-5 0}, {0 0}, {5 0}, {10 0}, {0 -10}, {0 -5}, {0 0}, {0 5}, {0 10}});
    e.trials.add('onset', ExponentialDistribution('offset', 0.25, 'tau', 0.5));

    e.trials.setDisplayFunc(@showCalibration);
    
    handle = figure(3); clf;
    ax = axes();
    history = 0;
    set(handle, 'ButtonDownFcn', @clear)

    function clear(x, y)
        history = 0;
    end
    
    function showCalibration(results)
        r = results(max(1,end-history):end);
        i = interface(struct('target', {}, 'endpoint', {}), r);
        t = cat(1, i.target);
        endpoints = cat(1, i.endpoint);
        axes(ax); cla; hold on;
        plot(t(:,1), t(:,2), 'g.', e(:,1), e(:,2), 'rx');
        line([t(:,1)';endpoints(:,1)'], [t(:,2)';endpoints(:,2)'], 'Color', 'b');
        axis equal;
        drawnow;
        history = history + 1;
        
        %solve the calibration...
        orig_offset = e.params.input.eyes.getOffset();
        orig_slope = e.params.input.eyes.getSlope();
        raw = endpoints'/orig_slope - orig_offset(:, ones(1, numel(i)));
        
        if numel(i) >= 3
            %this solution works easiest in affine coordinates
            atarg = t';
            atarg(3,:) = 1;
            araw = raw;

            %araw * amat = atarg (in least squares sense)
            amat = araw \ atarg;
            calib = araw * amat;
            
            plot(calib(1,:), calib(2,:), 'b+');
        end
    end
    
end


