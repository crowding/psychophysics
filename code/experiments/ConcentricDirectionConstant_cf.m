function exp = ConcentricDirectionConstant_cf(exp)
%6   8    10    13    15 16    18    23    30
%    8    10    13    15 16    18    23    30 35
%    8    10    13    15 16    18    23 26 30
%    8    10    13    15 16    18 20 23 26
    
    exp.trials.replace('extra.nTargets', [11 13 15 18 21 25 30 35]);
    
    exp.trials.reps = 5;
    exp.trials.blockSize = 160;
    
    exp.trials.replace('motion.process.t', 0.25);
    exp.trials.replace('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* (b.motion.process.n)));
    exp.trials.base.maxResponseLatency = 0.50;
end
