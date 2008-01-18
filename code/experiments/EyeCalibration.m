function e = EyeCalibration(varargin)

    e = Experiment(varargin{:});
    e.trials.base = EyeCalibrationTrial();
    e.trials.base.absoluteWindow = 100;
    e.trials.base.maxLatency = 0.5;
    e.trials.base.fixDuration = 0.5;
    e.trials.base.fixWindow = 3;
    e.trials.base.rewardDuration = 150;

    e.trials.add('targetY', [-10  0 10]);
    e.trials.add('targetX', [-10  0 10]);
%    e.trials.add({'targetX', 'targetY'}, {{-10 0} {-5 0}, {0 0}, {5 0}, {10 0}, {0 -10}, {0 -5}, {0 0}, {0 5}, {0 10}});
    e.trials.add('onset', @()0.25 - 0.5*log(rand));

    e.trials.setDisplayFunc(@showCalibration);

end

function showCalibration(results)
    r = results(max(1,end-20):end);
    i = interface(struct('target', {}, 'endpoint', {}), r);
    t = cat(1, i.target);
    e = cat(1, i.endpoint);
    figure(3);
    clf;
    hold on;
    plot(t(:,1), t(:,2), 'g.', e(:,1), e(:,2), 'rx');
    line([t(:,1)';e(:,1)'], [t(:,2)';e(:,2)'], 'Color', 'b');
    axis equal;
end
