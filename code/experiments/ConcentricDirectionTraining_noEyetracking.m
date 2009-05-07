function e = ConcentricDirectionTraining_noEyetracking(varargin)
    e = ConcentricDirectionTraining(varargin{:});

    e.trials.blockTrial = [];
    e.trials.base.requireFixation = 0;
    e.params.input.eyes = BeepOutput();
end