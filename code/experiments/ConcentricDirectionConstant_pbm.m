function exp = ConcentricDirectionConstant_pbm(exp)
    exp.trials.replace('extra.nTargets', [8 10 13 15 16 18 23 30 35])
    exp.trials.reps = 4;
    exp.trials.blockSize = 144;
    %exp.trials.base.requireFixation = 0;
    %exp.params.inputUsed = {'keyboard', 'knob', 'audioout'};
    %exp.trials.blockTrial = [];
end