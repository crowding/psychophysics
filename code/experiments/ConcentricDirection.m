function e = ConcentricDirection(varargin)

    params = namedargs ...
        ( localExperimentParams() ...
        , 'skipFrames', 1  ...
        , 'priority', 9 ...
        , 'hideCursor', 0 ...
        , 'doTrackerSetup', 1 ...
        , 'input', struct ...
            ( 'keyboard', KeyboardInput() ...
            , 'knob', PowermateInput() ...
            ) ...
        , varargin{:});
    
    e = Experiment('params', params);

    e.trials.base = ConcentricTrial...
        ( 'fixationStartWindow', 3 ...
        , 'fixationSettle', 0.3 ...
        , 'fixationWindow', 1 ...
        , 'motion', CauchySpritePlayer ...
            ( 'process', CircularCauchyMotion ...
                ( 'radius', 10 ...
                , 'dt', 0.15 ...
                , 'dphase', 0.25/8 ...
                , 'x', 0 ...
                , 'y', 0 ...
                , 't', 0.5 ...
                , 'n', 4 ...
                , 'color', [0.5 0.5 0.5]' ...
                , 'velocity', 5 ... %velocity of peak spatial frequency
                , 'wavelength', 0.375 ...
                , 'width', 0.25 ...
                , 'duration', 0.1 ...
                , 'order', 4 ...
                ) ...
            ) ...
        );
    
    e.trials.interTrialInterval = 0.5;
        %what worked well in the wheels demo is 0.75 dx, 0.75 wavelength, 0.15
    %dt, 5 velocity at 14 radius! The crowding was 3.1 degrees!
    %Thsi scales down to ... less than that at 8 degrees. Chop everything
    %in half.
    
    %randomize global and local direction....
    e.trials.add('extra.dx', [-0.5 0.5]);
    e.trials.add('motion.process.radius', [5 6 7 8]);
    e.trials.add('motion.process.dphase', @(b)b.extra.dx ./ b.motion.process.radius);

    e.trials.add('extra.nTargets', [10 12 15 18 20]);
    e.trials.add('motion.process.phase', @(b) mod(rand()*2*pi + (0:b.extra.nTargets-1)/b.extra.nTargets*2*pi, 2*pi));
    e.trials.add('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* (b.motion.process.n + 1)));
    
    %supporting, opposing, and ambiguous.
    %The ambiguous motion is ade up of two opposing motions superimposed,
    %so we have to double and elements (and halve the contrast) for that
    %one.
    e.trials.add...
        ( {'extra.relativeVelocity', 'motion.process.color', 'motion.process.phase'} ...
        , { {-1, [0.5;0.5;0.5], @(b)b.motion.process.phase}...
          , {@(b)reshape(repmat([-1 1], numel(b.motion.process.phase), 1), 1, []), [.25;.25;.25], @(b)repmat(b.motion.process.phase, 1, 2)}...
          , {1, [0.5;0.5;0.5], @(b)b.motion.process.phase} } );

    e.trials.add('motion.process.angle', @(b) mod(b.motion.process.phase * 180/pi + 90, 360));

    
    e.trials.add('motion.process.velocity', @(b)b.extra.dx ./ b.motion.process.dt .* b.extra.relativeVelocity);
    
    %pick a number of targets, and spread them around the circle
    %say, a spacing of 2 to 10 degrees...

    %say, 16 samples for each N, after folding directions?
    e.trials.reps = 8;
    e.trials.blockSize = 200;
    
    e.trials.fullFactorial = 1;

    e.trials.blockTrial = EyeCalibrationMessageTrial();
    e.trials.blockTrial.minCalibrationInterval = 0;
    e.trials.blockTrial.base.absoluteWindow = 100;
    e.trials.blockTrial.base.maxLatency = 0.5;
    e.trials.blockTrial.base.fixDuration = 0.5;
    e.trials.blockTrial.base.fixWindow = 4;
    e.trials.blockTrial.base.rewardDuration = 10;
    e.trials.blockTrial.base.settleTime = 0.3;
    e.trials.blockTrial.base.targetRadius = 0.2;
    e.trials.blockTrial.base.onset = 0;
    e.trials.blockTrial.maxStderr = 0.5;
    e.trials.blockTrial.minN = 10;
    e.trials.blockTrial.maxN = 50;
    e.trials.blockTrial.interTrialInterval = 0.4;
    e.trials.blockTrial.beginMessage = MessageTrial('message', @()sprintf('Press knob to continue. %d blocks remain', e.trials.blocksLeft()));
end