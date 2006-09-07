function this = SaccadeToTarget(varargin)
%a trial executing a saccade to target.
%
%takes a parameter 'timeDilation' that lengthens the trial by a
%multiplicative factor, and a parameter 'diagnostics' to show diagnostic
%information

%the trial params are big enough to go in a 'trialParams' namespace
%A little juggling for the time dilation and passed arguments
defaults = namedargs(...
      'successful', 0 ...
    , 'trialParams.timeDilation', '__auto__' ...
    , 'err', [] ...
    , 'clock', [] ...
    );

%we like Object access syntax/saving but want fast access to the struct
[this, props] = Object(...
    propertiesfromdefaults(defaults, 'params', varargin{:}), ...
    public(@getTrialParams, @setTrialParams, @run));

%we use the trial params struct a lot, so take it into a local struct
p = props.getTrialParams();
if isequal(p.timeDilation, '__auto__')
    if params.dummy
        p.timeDilation = 3;
    else
        p.timeDilation = 1;
    end
end

p = namedargs(...
%{
    'target', ApparentMotion(... %this target identical to my interpolation experiment
        'primitive', CauchyBar(...
            'size', [0.375 1 0.075*p.timeDilation],...
            'velocity', 5/p.timeDilation),...
        'dx', 1, 'dt', 0.2*p.timeDilation,...
        'n', 10,...
        'center', [-4.5 5 0*p.timeDilation]),...
%}
    'target', ApparentMotion(... %this target identical to the interpolation exp, scaled 1.5x
        'primitive', CauchyBar(...
            'size', [0.5625 2 0.075*p.timeDilation],...
            'velocity', 7.5/p.timeDilation),...
        'dx', 1.5, 'dt', 0.2*p.timeDilation,...
        'n', 10,...
        'center', [-6.75 7.5 0*p.timeDilation]),...
%{
    'target', ApparentMotion(... %this target identical to my velocity judgement experiment
        'primitive', CauchyBar(...
            'size', [0.375 1 0.075*p.timeDilation],...
            'velocity', 5/p.timeDilation),...
        'dx', 1, 'dt', 0.2*p.timeDilation,...
        'n', 10,...
        'center', [-4.5 5 0*p.timeDilation]),...
%}
    'fixationLocation',       [0 0],...
    'fixationPointRadius',    0.1,...
    'grossFixationCriterion', 3,... %the window which starts a trial
    'fixationSettlingTime',   0.35,... %wait this long to settle fixation
    'fineFixationCriterion',  0.75,... %eye stays in this radius when fixating
    'targetMargin',           1,... %how close you need to get to the target
    ...
    'fineFixationTime',       0.75 * p.timeDilation,...
    'nAveragingSamples',      10,... %how many samples to take of eye position average
    'cueTime',                0.40 * p.timeDilation,... %wait before cueing
    'cueSaccade',             1,... %whether to cue the saccade
    'saccadeReactionTime',    0.00 * p.timeDilation,... %min reaction time
    'saccadeWindowTime',      0.50 * p.timeDilation,... %window for saccade to begin
    'saccadeTransitTime',     0.15 * p.timeDilation,... %how long a saccade has
    ...
    'goodTrialTones',         [750 0.05 0 750 0.2 0.9],...
    'goodTrialTimeout',       0,...
    'badTrialTones',          repmat([500 0.1 0.9 0 0.1 0], 1, 5),...
    'badTrialTimeout',        2,...
    ...
    'diagnostics', 0,...     %whether to show the diagnostic displays
    ...  
    p...                     %note p at end - passed arguments override defaults
    );

%override trialParams accessors
    function out = getTrialParams()
        out = p;
    end
    
    function setTrialParams(in)
        p = in;
    end


    function params = run(varargin)
        params = namedargs(this.params, varargin{:});
        
        this.clock = clock();
        this.successful = 0;
        %-----stimulus components----

        fixation = FilledDisk(...
            p.fixationLocation, p.fixationPointRadius, ...
            [params.blackIndex params.blackIndex params.whiteIndex]);

        target = MoviePlayer(p.target);
        
        %triggers are expensive to create, so we will share them across
        %states.
        nearTrigger = NearTrigger();
        farTrigger = FarTrigger();
        timeTrigger = TimeTrigger();
        insideTrigger = InsideTrigger();

        
        %----- build the main loop.-----
        %matlab is so freaking slow at altering structs in lexical scope
        %that I have to give the graphics and triggers as constructor
        %arguments.
        
        if p.diagnostics
            %----- visible state and gaze indicator (development feedback) ----
            state = Text([-5 -5], '', [0 0 params.whiteIndex]);
            state.setVisible(1);

            gaze = FilledDisk([0 0], 0.1, [params.whiteIndex 0 0]);
            gazeupdate = UpdateTrigger(@(x, y, t, next) gaze.setLoc([x y]));
            gaze.setVisible(1);
            
            outlines = TriggerDrawer();
            outlines.setVisible(1);
            
            main = mainLoop(...
                {fixation, target, state, gaze, outlines}...
                ,{nearTrigger, farTrigger, timeTrigger, insideTrigger, gazeupdate}...
                );
            outlines.set(main);
        else
            main = mainLoop(...
                {fixation, target}...
                ,{nearTrigger, farTrigger, timeTrigger, insideTrigger}...
                );
        end
        
        %----- shared-state variables -----
        observedFixation = [0, 0];
        stimulusOnset = 0;
        nSamples = 0;
        accumX = 0;
        accumY = 0;

        %----- begin -----
        %the first action is to go into the first state
        timeTrigger.set(0, @waitingForFixation);
        
        disp(sprintf('cue at %g s (%g deg)', ...
            p.cueTime, p.target.center(1) + p.target.dx/p.target.dt*p.cueTime));

        params = main.go(params);

        %----- state functions -----
        
        function waitingForFixation(x, y, t, next)
            fixation.setVisible(1);
            %gaze.setVisible(1);
            
            %fixation dot is blue while not inside the fixation window
            fixation.setColor(...
                [params.blackIndex params.blackIndex params.whiteIndex]);

            nearTrigger.set(...
                fixation.getLoc(), p.grossFixationCriterion, @settlingFixation);
            farTrigger.unset();
            timeTrigger.unset();
        end

        
        function settlingFixation(x, y, t, next)
            nearTrigger.unset();
            %gaze.setVisible(0);
            
            fixation.setColor(...
                [params.blackIndex params.blackIndex params.blackIndex]);
            
            farTrigger.set(...
                [x y], p.grossFixationCriterion, @waitingForFixation);
            
            %wait for settling, then average fixation
            accumX = 0;
            accumY = 0;
            nAveragingSamples = 0;
            timeTrigger.set(t + p.fixationSettlingTime, @averagingFixation, 1);
        end

        
        function averagingFixation(x, y, t, next)
            %this should be called for as many samples as are necessary
            accumX = accumX + x;
            accumY = accumY + y;
            nSamples = nSamples + 1;
            if (nSamples >= p.nAveragingSamples)
                observedFixation = [accumX, accumY] ./ nSamples;
                holdingFixation(x, y, t, next);
            end
        end
        
        
        function holdingFixation(x, y, t, next)
            nearTrigger.unset();
            farTrigger.set(...
                observedFixation, p.fineFixationCriterion, @waitingForFixation);
            timeTrigger.set(t + p.fineFixationTime, @showStimulus);
        end

        
        function showStimulus(x, y, t, next)
            stimulusOnset = target.setVisible(1, next);
            params.log('STIMULUS_ONSET %f', stimulusOnset);

            nearTrigger.unset();
            farTrigger.set(...
                observedFixation, p.fineFixationCriterion, @brokenFixation);
            
            if (p.cueSaccade)
                timeTrigger.set(...
                    stimulusOnset + p.cueTime, @cueSaccade);
            else
                timeTrigger.set(...
                    stimulusOnset + target.finishTime(), @completed);
            end     
        end

        
        function cueSaccade(x, y, t, next)
            fixation.setVisible(0);

            nearTrigger.unset();
            farTrigger.set(...
                observedFixation, p.fineFixationCriterion, @brokenFixation);
            timeTrigger.set(t + p.saccadeReactionTime, @awaitSaccade);
        end

        
        function awaitSaccade(x, y, t, next)
            nearTrigger.unset();
            timeTrigger.set(t + p.saccadeWindowTime, @failedSaccade);
            farTrigger.set(...
                observedFixation, p.fineFixationCriterion, @saccadeTransit);
            insideTrigger.set(target.bounds, p.targetMargin, observedFixation, @finishedSaccade);
        end
        

        function saccadeTransit(x, y, t, next)
            timeTrigger.unset();
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + p.saccadeTransitTime, @targetNotReached);
            insideTrigger.set(target.bounds, p.targetMargin, observedFixation, @finishedSaccade);
        end
        

        function finishedSaccade(x, y, t, next)
            insideTrigger.unset();
            nearTrigger.unset();
            farTrigger.unset();
            
            %wait until stimulus has ben shown
            timeTrigger.set(stimulusOnset + target.finishTime(), @completed);
        end
        
        
        function completed(x, y, t, next)
            main.stop();
            goodFeedback();

            %flag success for experiment protocols that reshuffle
            %failed trials
            this.successful = 1;
        end
        

        function targetNotReached(x, y, t, next)
            insideTrigger.unset();
            badTrial(x, y, t, next);
        end

        
        function failedSaccade(x, y, t, next)
            badTrial(x, y, t, next);
        end

        
        function brokenFixation(x, y, t, next)
            badTrial(x, y, t, next);
        end

        
        function badTrial(x, y, t, next)
            %clear screen
            target.setVisible(0);
            fixation.setVisible(0);

            %give feedback at next refresh
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + params.cal.interval, @finishBadTrial);
        end

        
        function finishBadTrial(x, y, t, next)
            main.stop();
            badFeedback();
        end

        
        function goodFeedback
            %sound constructed on the fly to save memory -- there will be
            %many trial objects and we record everything they remember
            play(tones(p.goodTrialTones)); 
            pause(p.goodTrialTimeout)
        end

        
        function badFeedback
            play(tones(p.badTrialTones));
            pause(p.badTrialTimeout);
        end

    end % ----- doTrial ----
end
