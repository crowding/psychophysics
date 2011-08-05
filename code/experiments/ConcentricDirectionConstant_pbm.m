function exp = ConcentricDirectionConstant_pbm(exp)
%6   8    10    13    15 16    18    23    30
%    8    10    13    15 16    18    23    30 35
%    8    10    13    15 16    18    23 26 30
%    8    10    13    15 16    18 20 23 26
    
    exp.trials.replace('extra.nTargets', [8    10    13    15 16    18 20 23 26]);
    exp.trials.reps = 4;
    exp.trials.blockSize = 144;
    %exp.trials.base.requireFixation = 0;
    %exp.params.inputUsed = {'keyboard', 'knob', 'audioout'};
    %exp.trials.blockTrial = [];
end