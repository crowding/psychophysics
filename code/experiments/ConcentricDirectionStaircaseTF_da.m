function exp = ConcentricDirectionStraircaseTF_da(exp)
    exp.trials.replace('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* (b.motion.process.n)) + 0.15);
    exp.trials.replace('motion.process.t', 0.25);

    exp.trials.base.maxResponseLatency = 0.50;
    exp.trials.reps = 9;
    exp.trials.blockSize = 162;
end
