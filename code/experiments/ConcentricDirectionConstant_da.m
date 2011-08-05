function exp = ConcentricDirectionConstant_da(exp)
%6   8    10    13    15 16    18    23    30
%    8    10    13    15 16    18    23    30 35
%    8    10    13    15 16    18    23 26 30
%    8    10    13    15 16    18 20 23 26
    
    exp.trials.replace('extra.nTargets', [5 6 7 9 12 15 20]);
    exp.trials.reps = 4;
    exp.trials.blockSize = 168;
    exp.trials.replace('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* (b.motion.process.n)) + 0.15);
    exp.trials.replace('motion.process.t', 0.25);


    %exp.trials.replace('extra.r', [10 20/3 40/9]);
    %exp.trials.base.requireFixation = 0;
    %exp.params.inputUsed = {'keyboard', 'knob', 'audioout'};
    %exp.trials.blockTrial = [];
    exp.trials.base.maxResponseLatency = 0.50;
end
