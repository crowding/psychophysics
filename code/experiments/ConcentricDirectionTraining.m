function e = ConcentricDirectionTraining(varargin)
%like ConcentricDirectionConstant with easier stimuli and NO DISAGREEMENT.

    params = namedargs ...
        ( localExperimentParams() ...
        , 'skipFrames', 1  ...
        , 'priority', 0 ...
        , 'hideCursor', 0 ...
        , 'doTrackerSetup', 1 ...
        , 'input', struct ...
            ( 'keyboard', KeyboardInput() ...
            , 'knob', PowermateInput() ...
            ) ...
        , 'eyelinkSettings.sample_rate', 250 ...
        , varargin{:});
    
    e = Experiment('params', params);

    e.trials.base = ConcentricTrial...
        ( 'extra', struct...
            ( 'r', 10 ...
            , 'globalVScalar', 0.5 ...
            , 'tf', 10 ...
            , 'wavelengthScalar', .05 ...
            , 'dt', 0.1 ...
            , 'widthScalar', 0.1 ...
            , 'durationScalar', 2/3 ...
            , 'nTargets', 10 ...
            , 'phase', 0 ...
            , 'globalDirection', 1 ...
            , 'localDirection', 1 ...
            , 'color', [0.5;0.5;0.5] / sqrt(2)...
            ) ...
        , 'requireFixation', 0 ...
        , 'fixationStartWindow', 3 ...
        , 'fixationSettle', 0.1 ...
        , 'fixationWindow', 4 ...
        , 'motion', CauchySpritePlayer ...
            ( 'process', CircularCauchyMotion ...
                ( 'x', 0 ...
                , 'y', 0 ...
                , 't', 0.5 ...
                , 'n', 6 ...
                , 'color', [0.5 0.5 0.5] ...
                , 'duration', 0.1 ...
                , 'order', 4 ...
                ) ...
            ) ...
        );
    
    e.trials.interTrialInterval = 0;
    
    %what worked well in the wheels demo is 0.75 dx, 0.75 wavelength, 0.15
    %dt, 5 velocity at 14 radius! The crowding was 3.1 degrees! Use the
    %same parameters at 10 degrees eccentricity.
    
    %the target and distractor are selected from a grid of stimulus
    %parameters.

%%
    %In this section, we build up the array of parameters we will quest with.
    e.trials.add({'extra.r'}, {80/27 10 20/3 40/9});
    %e.trials.add({'extra.r'}, {80/27});
    
    %these are multiplied by radius to get global velocity, centereed
    %around 10 deg/dec at 10 radius... that is to say this is merely
    %radians/sec around the circle.
    %%e.trials.add({'extra.globalVScalar'}, {2/6 .5 .75});
    e.trials.add({'extra.globalVScalar'}, {.5});
    
    %temporal frequency is chosen here...
    %%e.trials.add({'extra.tf'}, {15 10 20/3});
    e.trials.add({'extra.tf'}, {10});

    %and wavelength is set to the RADIUS multiplied by this (note
    %this is independent of dt or dx)
    %%e.trials.add({'extra.wavelengthScalar'}, {.05 .075 .1125});
    e.trials.add({'extra.wavelengthScalar'}, {.05});
    
    %dt changes independently of it all, but it is linked to the stimulus
    %duration.
    %%e.trials.add({'extra.dt', 'motion.process.n'}, {{2/30 9}, {0.10 6} {0.15 4}});
    e.trials.add({'extra.dt', 'motion.process.n'}, {{0.10 6}});
    
    %here we use constant stimuli... in number of targets.
    e.trials.add({'extra.nTargets'}, {6 8 10 12 15 20 26});
%%
        
    %randomize global and local direction....
    e.trials.add('extra.phase', UniformDistribution('lower', 0, 'upper', 2*pi));
    
    %here's where local and global are randomized
    e.trials.add({'extra.globalDirection', 'extra.localDirection'}, {{-1 -1}, {-1 0}, {1 0}, {1 1}});
    
    %await the input after the stimulus has finished playing.
    e.trials.add('awaitInput', @(b) max(b.motion.process.t + b.motion.process.dt .* (b.motion.process.n + 1)));
    
    %this procedure translates the extra parmeters into lower level values.
    e.trials.add([], @appearance);
    function b = appearance(b)
        extra = b.extra;
        mot = b.motion.process;
        mot.setRadius(extra.r);
        mot.setDt(extra.dt);
        mot.setT(extra.dt);
        mot.setDphase(extra.dt .* extra.globalVScalar .* extra.globalDirection);
        wl = extra.r * extra.wavelengthScalar;
        mot.setWavelength(wl);
        mot.setWidth(extra.r .* extra.widthScalar);
        mot.setDuration(extra.durationScalar .* extra.dt);
        
        ph = mod(extra.phase + (0:extra.nTargets-1)/extra.nTargets*2*pi, 2*pi);
        %For balance we need to have three kinds of motion: supporting, opposing, and ambiguous.

        if extra.localDirection ~= 0
            mot.setPhase(ph);
            mot.setAngle(mod(ph*180/pi + 90, 360));
            mot.setVelocity(wl .* extra.tf .* extra.localDirection);
            mot.setColor(extra.color);
        else
            %The ambiguous motion is made up of two opposing motions superimposed,
            %so we have to double and elements (and reduce the contrast)
            %for that one.
            ph = reshape(repmat(ph, 2, 1), 1, []);
            mot.setPhase(ph);
            mot.setAngle(mod(ph*180/pi + 90, 360));
            mot.setVelocity(wl .* extra.tf * repmat([-1 1], 1, extra.nTargets));
            mot.setColor(extra.color / sqrt(2));
        end
    end
    
    %say, run 30 trials for each quest, with an estimated threshold value measured in number of
    %targets, somewhere between 5 and 20. This arrives at a threshold
    %estimate very quickly.
    %note that of the global and local combinations, 2 will inform the
    %quest. So 15 reps of the factorial means 30 trials in the quest.
    e.trials.reps = 8;
    e.trials.fullFactorial = 1;
    e.trials.requireSuccess = 1;
    e.trials.blockSize = 192;

    e.trials.startTrial = MessageTrial('message', @()sprintf('Use knob to indicate direction of rotation.\nPress knob to begin.\n%d blocks in experiment', e.trials.blocksLeft()));
    e.trials.endBlockTrial = MessageTrial('message', @()sprintf('Press knob to continue.\n%d blocks remain', e.trials.blocksLeft()));

    e.trials.endTrial = MessageTrial('message', sprintf('All done!\nPress knob to save and exit.\nThanks!'));
end