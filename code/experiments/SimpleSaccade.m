function e = SimpleSaccade(varargin)
    e = Experiment(varargin{:});
    
    e.trials.base = SimpleSaccadeTrial();
    e.trials.add('targetPhase', @(x)rand(1) * 2 * pi );
    e.trials.add('fixationTime', @(x)0.75 - 0.5 * log(rand()));
    %target onset hazard
    e.trials.add('targetOnset', @(x)0.25 - 0.5 * log(rand()));
    %target fixation hazard
    e.trials.add('targetFixationTime', @(x)0.3 - 0.25 * log(rand()));
    
    
end