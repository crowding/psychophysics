function exp = ConcentricDirectionConstant_jt(exp)
%6   8    10    13    15 16    18    23    30
%    8    10    13    15 16    18    23    30 35
%    8    10    13    15 16    18    23 26 30
%    8    10    13    15 16    18 20 23 26
    
    exp.trials.replace('extra.nTargets', [6 7 9 12 15 20 24 28]);
    
    exp.trials.reps = 5;
    exp.trials.blockSize = 160;
    
    exp.trials.replace('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* (b.motion.process.n)) + 0.15);
    exp.trials.replace('motion.process.t', 0.25);
    exp.trials.base.maxResponseLatency = 0.50;
end
