function this = ConcentricDirectionDiscriminabilityStrokes(varargin)
    %for a certain set of local motion contrasts, and a certain set of
    %global motion contrasts, 

    this = ConcentricDirectionConstant();
    this.caller=getversion(1);
    
    this.params.input.audioout.property__('samples.cue', Chirp('beginfreq', 1000, 'endfreq', 1e-6, 'length', 0.05, 'decay', 0.01, 'release', 0.005, 'sweep', 'exponential'));
        
    this.trials.remove('extra.r');
    this.trials.remove('extra.nTargets');
    this.trials.remove('extra.globalDirection');
    this.trials.remove('extra.localDirection');
        
    % a reasonable value set for DX.
    valueSet = [-.1 .* (3/2).^((10:-1:1)./2) -.1:.025:.1 .1 .* (3/2).^((1:10)./2)];
    
    % a 3-down, 1-up staircase.
    makeDxUpperStaircase = @()DiscreteStaircase...
        ( 'criterion', @directionCorrect...
        , 'Nup', 1, 'Ndown', 3, 'useMomentum', 1 ...
        , 'valueSet', valueSet, 'currentIndex', 24);

    %a 3-up, 1-down staircase
    makeDxLowerStaircase = @()DiscreteStaircase...
        ( 'criterion', @directionCorrect...
        , 'Nup', 3, 'Ndown', 1, 'useMomentum', 1 ...
        , 'valueSet', valueSet, 'currentIndex', 6);
    
    this.trials.addBefore...
        ( 'extra.phase' ...
        , {'extra.globalDirection', 'extra.localDirection'}...
        , { { 1, 1 }, { -1, -1 } })
    
    
    this.trials.addBefore...
        ( 'extra.phase' ...
        , { 'extra.r' ...
          , 'extra.nTargets' ...
          , 'extra.globalVScalar'...
          , 'extra.directionContrast'...
          , 'extra.nStrokes'...
          } ...
%{
%let's test a few densities (4, 8, 16, 20) at 2/3/4/5 strokes
%}
        , { { 20/3, 4,  makeDxUpperStaircase(),     .20, 2} ...
          , { 20/3, 4,  makeDxLowerStaircase(),     .20, 2} ...
          , { 20/3, 4,  makeDxUpperStaircase(),     .20, 3} ...
          , { 20/3, 4,  makeDxLowerStaircase(),     .20, 3} ...
          , { 20/3, 4,  makeDxUpperStaircase(),     .20, 4} ...
          , { 20/3, 4,  makeDxLowerStaircase(),     .20, 4} ...
          , { 20/3, 4,  makeDxUpperStaircase(),     .20, 5} ...
          , { 20/3, 4,  makeDxLowerStaircase(),     .20, 5} ...
          , { 20/3, 18,  makeDxUpperStaircase(),    .20, 2} ...
          , { 20/3, 18,  makeDxLowerStaircase(),    .20, 2} ...
          , { 20/3, 18,  makeDxUpperStaircase(),    .20, 3} ...
          , { 20/3, 18,  makeDxLowerStaircase(),    .20, 3} ...
          , { 20/3, 18,  makeDxUpperStaircase(),    .20, 4} ...
          , { 20/3, 18,  makeDxLowerStaircase(),    .20, 4} ...
          , { 20/3, 18,  makeDxUpperStaircase(),    .20, 5} ...
          , { 20/3, 18,  makeDxLowerStaircase(),    .20, 5} ...
%}
        });
    
    %use the same time onset for all trials
    this.trials.replace('motion.process.t', 0.3);
    this.trials.replace('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* 4));
	this.trials.base.extra.audioCueLatency = [-1 -0.5];
    this.trials.base.extra.responseWindowLatency = 0.9;
    this.trials.base.extra.responseWindowTolerance = 0.1;
    
    this.trials.add('awaitInput', @(b)b.motion.process.t(1) + b.extra.responseWindowLatency - b.extra.responseWindowTolerance);
    this.trials.add('audioCueTimes', @(b)b.motion.process.t(1) + b.extra.responseWindowLatency + b.extra.audioCueLatency);
    this.trials.add('maxResponseLatency', @(b)b.extra.responseWindowTolerance*2);

    this.trials.add('desiredResponse', 0);

    this.trials.reps = 1;
    this.trials.reps = floor(1100 / this.trials.numLeft());
    this.trials.blockSize = ceil(this.trials.numLeft() / 5);
    
    
    %determines whether the detected mtoion direction aggrees with global
    %displacement.
    function correct = directionCorrect(trial, result)
        correct = 0;
        if result.success == 1
            gd = trial.property__('extra.globalDirection');
            ld = trial.property__('extra.localDirection');
            if (sign(gd) == -sign(ld))
                return
            end
            if gd == 0
                if result.response == -ld
                    correct = 1;
                else
                    correct = -1;
                end
            else
                if result.response == -gd;
                    correct = 1;
                else
                    correct = -1;
                end
            end
        end
    end
    
    this.property__(varargin{:});
end
