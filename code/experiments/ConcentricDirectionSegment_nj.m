function exp = ConcentricDirectionSegment_nj(exp)
    disp('configuring for nj');
    
    %set the global speed.
    exp.trials.base.extra.directionContrast = .4;
    %we're just looking at one combination of contrast and two values of
    %global V...
    %We want 0.1 and 0.2 degree displacement to be most informative
    displacement = [-.1 -.2] * 20/3 * 0.1;
    exp.trials.addBefore('extra.globalDirection', 'extra.globalVScalar', {displacement(1), displacement(2)});
    exp.trials.addBefore('extra.globalDirection', {'extra.globalDirection', 'extra.localDirection'}, {{1 1},{-1 -1}});
    exp.trials.remove('extra.globalDirection');
    exp.trials.remove('extra.localDirection');
    
    exp.trials.replace('extra.side', {...
        'left', 'right', 'right', 'left', ...
        'left', 'right', 'right', 'left', ...
        'left', 'right', 'right', 'left', ...
        'left', 'right'}, 1, 1); %side is blocked

    exp.trials.add('desiredResponse', 0);
    
    exp.trials.blockSize = exp.trials.numLeft() / 7;
    
end