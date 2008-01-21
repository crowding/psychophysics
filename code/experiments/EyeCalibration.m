function e = EyeCalibration(varargin)

    e = Experiment(varargin{:});
    e.trials.base = EyeCalibrationTrial();
    e.trials.base.absoluteWindow = 5;
    e.trials.base.maxLatency = 0.5;
    e.trials.base.fixDuration = 0.3;
    e.trials.base.fixWindow = 3;
    e.trials.base.rewardDuration = 100;

    e.trials.add('targetY', [-10 -5 0 5 10]);
    e.trials.add('targetX', [-5]);
%    e.trials.add({'targetX', 'targetY'}, {{-10 0} {-5 0}, {0 0}, {5 0}, {10 0}, {0 -10}, {0 -5}, {0 0}, {0 5}, {0 10}});
    e.trials.add('onset', @()0.25 - 0.5*log(rand));

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
        e = cat(1, i.endpoint);
        axes(ax); cla; hold on;
        plot(t(:,1), t(:,2), 'g.', e(:,1), e(:,2), 'rx');
        line([t(:,1)';e(:,1)'], [t(:,2)';e(:,2)'], 'Color', 'b');
        axis equal;
        drawnow;
        history = history + 1;
        
    end
    
end


