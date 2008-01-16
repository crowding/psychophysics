function e = EyeCalibration(varargin)

    e = Experiment(varargin{:});
    e.trials.base = EyeCalibrationTrial();
    e.trials.base.absoluteWindow = 100;
    e.trials.base.maxLatency = 0.5;
    e.trials.base.fixDuration = 0.4;
    e.trials.base.fixWindow = 3;
    e.trials.base.rewardDuration = 200;

    e.trials.add('targetX', [0]);
    e.trials.add('targetY', [-10 -5 0 5 10]);
    e.trials.add('onset', @()0.25 - 0.5*log(rand));

    e.setDisplayFunc(@showCalibration);
end

function showCalibration(result)
    r = e.trials.results(max(1,end-10,end));
end