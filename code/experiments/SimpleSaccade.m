function e = SimpleSaccade(varargin)
    e = Experiment(varargin{:});
    
    e.trials.base = SimpleSaccadeTrial...
        ( 'targetLoc', CircularMotion ...
            ( 'radius', 8 ...
            , 'omega', 0 ...
            )...
        );
    
    e.trials.add('targetLoc.phase', @(x)rand(1) * 2 * pi );
    e.trials.add('fixationTime', @(x)0.5 - 0.4 * log(rand()));
    e.trials.add('targetLoc.omega', @(x) randc(1) / x.targetLoc.radius * 15);
    
    %target onset hazard
    e.trials.add('targetOnset', @(x)0.25 - 0.4 * log(rand()));
    
    %target fixation hazard
    e.trials.add('targetFixationTime', @(x)0.4 - 0.3 * log(rand()));
    
end