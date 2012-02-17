function exp = ConcentricDirectionDiscriminabilityStrokes_zzz(exp)
    disp('configuring for zzz');
    
    %set the global speed.
    %we're just looking at one combination of contrast and two values of
    %global V...
    %We want 0.1 and 0.2 degree displacement to be most informative
    
    exp.trials.blockSize = exp.trials.numLeft() / 7;
    
    exp.trials.base.requireFixation = 0;
    exp.trials.blockTrial = [];
    exp.params.inputUsed = {'keyboard',  'knob',  'audioout'};
end