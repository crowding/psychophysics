function exp = ConcentricDirectionConstant_pbm(exp)
    exp.trials.replace('extra.nTargets', [6 9 12 15 18 21 23 25])
    exp.trials.reps = 5;
    exp.trials.blockSize = 160;
    exp.trials.base.requireFixation = 0;
    exp.params.inputUsed = {'keyboard', 'knob', 'audioout'};
    exp.trials.blockTrial = [];
end