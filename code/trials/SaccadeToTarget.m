function this = SaccadeToTarget(varargin)
%a trial executing a saccade to target.
%
%takes a parameter 'timeDilation' that lengthens the trial by a
%multiplicative factor, and a parameter 'diagnostics' to show diagnostic
%information

this = ObjectWrapper(public(@params, @setParams, @run));

%little juggling to get time dilation parameter to affect the defaults...
p = namedargs('timeDilation', 1, varargin{:});

%default values
p = namedargs(...
    'target', ApparentMotion(... %the target (a @Patch object)
        'primitive', CauchyBar(...
            'size', [0.5 1 0.05*p.timeDilation],...
            'velocity', 10/p.timeDilation),...
        'dx', 1, 'dt', 0.1*p.timeDilation,...
        'n', 10,...
        'center', [-4.5 5 0*p.timeDilation]),...
    'fixationLocation',       [0 0],...
    'fixationPointRadius',    0.1,...
    'grossFixationCriterion', 3,... %the window which starts a trial
    'fixationSettlingTime',   0.35,... %wait this long to settle fixation
    'fineFixationCriterion',  0.75,... %eye stays in this radius when fixating
    'targetMargin',           1,... %how close you ned to get to the target
    ...
    'fineFixationTime',       0.75 * p.timeDilation,...
    'stimulusDisplayTime',    0.40 * p.timeDilation,... %wait before cueing
    'saccadeReactionTime',    0.00 * p.timeDilation,... %min reaction time
    'saccadeWindowTime',      0.50 * p.timeDilation,... %window for saccade to begin
    'saccadeTransitTime',     0.15 * p.timeDilation,... %how long a saccade has to make it to the target
    ...
    'goodTrialTones',         [750 0.2 0.9],...
    'goodTrialTimeout',       0,...
    'badTrialTones',          repmat([500 0.1 0.9 0 0.1 0], 1, 5),...
    'badTrialTimeout',        2,...
    ...
    'diagnostics', 0,...     %whether to show the diagnostic displays
    p... %note p at end - given arguments override defaults
    );

    function out = params()
        out = p;
    end

    function setParams(in)
        p = in;
    end

    function run(details, logger)
        
        [main, canvas, events] = mainLoop(details);

        %-----stimulus components----

        fixation = FilledDisk(...
            p.fixationLocation, p.fixationPointRadius, details.blackIndex);
        canvas.add(fixation);

        target = MoviePlayer(p.target);
        canvas.add(target);

        %----- visible state and gaze indicator (development feedback) ----
        if p.diagnostics
            state = Text([-5 -5], '', [0 0 details.whiteIndex]);
            canvas.add(state);
            state.setVisible(1);

            gaze = FilledDisk([0 0], 0.1, [details.whiteIndex 0 0]);
            canvas.add(gaze);
            gaze.setVisible(1);
            events.add(UpdateTrigger(@(x, y, t, next) gaze.setLoc([x y])));
            
            
            outlines = TriggerDrawer(events);
            canvas.add(outlines);
            outlines.setVisible(1);
        end

        %----- shared-state variables -----
        observedFixation = [0, 0];

        %triggers are expensive to create, so we will share them across
        %states.
        nearTrigger = NearTrigger();
        farTrigger = FarTrigger();
        timeTrigger = TimeTrigger();
        insideTrigger = InsideTrigger();

        events.add(nearTrigger);
        events.add(farTrigger);
        events.add(timeTrigger);
        events.add(insideTrigger);
        
        %the first action is to go into the first state
        timeTrigger.set(0, @waitingForFixation);

        main.go(details);

        %----- state functions -----

        function waitingForFixation(x, y, t, next)
            fixation.setVisible(1);

            nearTrigger.set(...
                fixation.loc(), p.grossFixationCriterion, @settlingFixation);
            farTrigger.unset();
            timeTrigger.unset();
        end

        function settlingFixation(x, y, t, next)
            nearTrigger.unset();
            farTrigger.set(...
                [x y], p.grossFixationCriterion, @waitingForFixation);
            %after settling, the next valid sample goes into the holding
            %pattern.
            timeTrigger.set(t + p.fixationSettlingTime, @holdingFixation, 1);
        end

        function holdingFixation(x, y, t, next)
            observedFixation = [x, y];

            nearTrigger.unset();
            farTrigger.set(...
                observedFixation, p.fineFixationCriterion, @waitingForFixation);
            timeTrigger.set(t + p.fineFixationTime, @showStimulus);
        end

        function showStimulus(x, y, t, next)
            %does it stop recording if I drift correct? Yes.
            
            %status = Eyelink( 'DriftCorrStart', 400, 300);
            %Eyelink('SendKeyButton', double('A'), 0, details.el.KB_PRESS);
           
            %we tell the target when the next refresh is, and the target
            %tells us when its time-zero is.
            onset = target.setVisible(1, next);

            nearTrigger.unset();
            farTrigger.set(...
                observedFixation, p.fineFixationCriterion, @brokenFixation);
            
            timeTrigger.set(...
                onset + p.stimulusDisplayTime, @cueSaccade);
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
            insideTrigger.set(target, p.targetMargin, @completeTrial);
        end

        function saccadeTransit(x, y, t, next)
            insideTrigger.set(target, p.targetMargin, @completeTrial);
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + p.saccadeTransitTime, @targetNotReached);
        end

        function completeTrial(x, y, t, next)
            insideTrigger.unset();
            nearTrigger.unset();
            farTrigger.unset();
            
            %spin on waitFinished until trial is over
            timeTrigger.set(0, @waitFinished);
        end
        
        function waitFinished(x, y, t, next) 
            if ~target.visible()
                main.stop();
                goodFeedback();
            end
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
            timeTrigger.set(t + details.cal.interval, @finishBadTrial);
        end

        function finishBadTrial(x, y, t, next)
            main.stop();
            badFeedback();
        end

        function goodFeedback
            play(tones(p.goodTrialTones)); %done on the fly to save memory -- there will be many trial objects
            pause(p.goodTrialTimeout)
        end

        function badFeedback
            play(tones(p.badTrialTones));
            pause(p.badTrialTimeout);
        end

    end % ----- doTrial ----
end