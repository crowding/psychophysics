function e = GloLoPulse_fast(varargin)

    e = Experiment...
        ( 'params', struct...
            ( 'skipFrames', 1  ...
            , 'priority', 9 ...
            , 'hideCursor', 0 ...
            , 'doTrackerSetup', 1 ...
            , 'inputUsed', {{'keyboard', 'knob', 'eyes'}}...
            )...
        , varargin{:} ...
        );
    
    e.trials.base = GloLoCuedTrial...
        ( 'barOnset', 0 ...                         %randomized below
        , 'barCueDuration', 1/30 ...
        , 'barCueDelay', 0.3 ...
        , 'barFlashColor', [0.75 0.75 0.75] ...
        , 'barFlashDuration', 1/30 ...
        , 'barLength', 2 ...
        , 'barWidth', 0.15 ...
        , 'barPhase', 0 ...                         %randomized below
        , 'barRadius', 8 ...
        , 'fixationPointSize', 0.1 ...
        , 'targets', { CauchySpritePlayer('process', ...
            InsertPulse('process', CircularCauchyMotion ...
            ( 'angle', 90 ...
            , 'color', [0.5; 0.5; 0.5] / sqrt(2) ...
            , 'dt', 0.1 ...
            , 'n', 5 ...
            , 'phase', 0 ...                        %randomized below
            , 'radius', 5 ...
            , 't', 0.1 ...
            , 'dphase', .15 ...
            , 'wavelength', 0.75 ...
            , 'width', .75 ...
            , 'duration', 2/30 ...
            , 'velocity', 7.5 ...
            , 'order', 4 ...
            )))}...
        , 'whichTargets', 1 ...
        );
        
    
    %The range of temporal offsets:
    %from the onset of the second flash to the onset of the fourth flash is
    %49 timepoints at 120 fps
    
    %The bar origin is random around the circle and orientation follows
    %motion phase, angle, bar onset, bar phase
    e.trials.add({'targets{1}.process.process.phase', 'targets{1}.process.process.angle'}, @(b)num2cell(rand()*2*pi * [1 180/pi] + [0 90]));
    e.trials.add({'targets{1}.process.process.velocity', 'targets{1}.process.process.dphase'}, {{-e.trials.base.targets{1}.process.process.velocity, -e.trials.base.targets{1}.process.process.dphase}, {e.trials.base.targets{1}.process.process.velocity, e.trials.base.targets{1}.process.process.dphase}});            
    
    
    %Pulse and measure simultaneous to the pulse:
    e.trials.add('targets{1}.process.pulseAt', [2 3 4]);
    %note pulseAt is 1-indexed...
    e.trials.add('barOnset', @(t)t.targets{1}.process.process.t + t.targets{1}.process.process.dt * (t.targets{1}.process.pulseAt - 1));
    
    %bar phase is sampled in a range...
    e.trials.add('extra.barStepsAhead', 0);
    e.trials.add('extra.barStepsAhead', linspace(-0.5, 3, 8));
    %that is centered on the location of the bar.
    e.trials.add('barPhase', @(b)b.extra.barStepsAhead*b.targets{1}.process.process.dphase + b.targets{1}.process.process.phase + (b.barOnset-b.targets{1}.process.process.t(1))*b.targets{1}.process.process.dphase ./ b.targets{1}.process.process.dt);

    %Two kinds of pulses: none, or faster.
    e.trials.add('targets{1}.process.pulse', ...
        { struct() ...
        , @(b)struct('wavelength', 2 * b.targets{1}.process.process.wavelength, 'color', [0.5;0.5;0.5] .* b.targets{1}.process.process.color, 'velocity', 2 * b.targets{1}.process.process.velocity) ...
        });

    %experiment logistics
    e.trials.fullFactorial = 1;
    e.trials.reps = 10;
    e.trials.blockSize = 160;

    e.trials.startTrial = MessageTrial('message', @()sprintf('Use knob to indicate direction of rotation.\nPress knob to begin.\n%d blocks in experiment', e.trials.blocksLeft()));
    e.trials.endBlockTrial = MessageTrial('message', @()sprintf('Press knob to continue.\n%d blocks remain', e.trials.blocksLeft()));

    e.trials.blockTrial = EyeCalibrationMessageTrial...
        ( 'minCalibrationInterval', 0 ...
        , 'base.absoluteWindow', Inf ...
        , 'base.maxLatency', 0.5 ...
        , 'base.fixDuration', 0.5 ...
        , 'base.fixWindow', 4 ...
        , 'base.rewardDuration', 10 ...
        , 'base.settleTime', 0.3 ...
        , 'base.targetRadius', 0.2 ...
        , 'base.plotOutcome', 0 ...
        , 'base.onset', 0 ...
        , 'maxStderr', 0.5 ...
        , 'minN', 10 ...
        , 'maxN', 50 ...
        , 'interTrialInterval', 0.4 ...
        );

    e.trials.endTrial = MessageTrial('message', sprintf('All done!\nPress knob to save and exit.\nThanks!'));
    