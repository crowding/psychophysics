function exp = ConcentricDirectionSegment_pbm(exp)
    disp('configuring for pbm');
    exp.trials.replace('extra.side', {'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left'}, 1, 1); %side is blocked
%    exp.trials.replace('extra.side', {'top', 'bottom', 'bottom', 'top', 'top', 'bottom', 'bottom', 'top'}, 1, 1); %side is blocked
    exp.trials.blockSize = exp.trials.numLeft() / 4;
end