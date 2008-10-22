function e = CalibrateEyes(varargin)
    e = Experiment(varargin{:});
        
    e.trials.base = EyeCalibrationMessageTrial();
    e.trials.numBlocks = 1;
    e.trials.blockSize = 1;
    e.trials.base.base.absoluteWindow = 100;
    e.trials.base.base.maxLatency = 0.5;
    e.trials.base.maxStderr = 0.5;
    e.trials.base.minCalibrationInterval = 0;
    e.trials.base.base.fixDuration = 0.7;
    e.trials.base.base.fixWindow = 4;
    e.trials.base.base.rewardDuration = 75;
    e.trials.base.base.settleTime = 0.3;
    e.trials.base.base.targetRadius = 0.4;
    e.trials.base.base.targetInnerRadius = 0.2;
    e.trials.base.base.onset = 0;
    e.trials.base.base.absoluteWindow = 8;
    e.trials.base.interTrialInterval = 0.5;
    e.trials.base.targetX = -15:5:15;
    e.trials.base.targetY = -15:5:15;
end
