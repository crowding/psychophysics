function e = EyeCalibration(varargin)

e = Experiment(varargin{:})
e.trials.base = EyeCalibrationTrial();

e.trials.add('targetX', [-10 -5 0 5 10]);
e.trials.add('targetY', [-10 -5 0 5 10]);
e.trials.add('onset', @()0.25 - 0.5*log(rand));
