function e = DistractedFixation(varargin)
    e = Experiment(varargin{:});
    
    e.trials.base = DistractedFixationTrial();
    e.trials.add('distractorPhase', @(x)rand(1) * 2 * pi );
    e.trials.add('distractorOnset', @(x)x.maxLatency - 0.3 * log(rand()));
    e.trials.add('fixationPointLoc(1)', [-2.5 0 2.5]);
    e.trials.add('fixationPointLoc(2)', [-2.5 0 2.5]);
end