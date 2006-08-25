function delayedSaccade()
%a gaze-contingent display using a trigger driven state-machine programming.

timeDilation = 3; %in mousemode, things should be slower.

patch = ApparentMotion(...
    'primitive', CauchyBar('size', [0.5 1 0.05*timeDilation], 'velocity', 10/timeDilation),...
    'dx', 1, 'dt', 0.1*timeDilation, 'n', 10, 'center', [0 5 0*timeDilation]);

%defaults for this kind of trial
fixationLocation = [0 0];
grossFixationCriterion = 3; %the window which starts a trial
fixationSettlingTime = 0.35; %ait this long for fixation to settle
fineFixationCriterion = 1; %whlie fixating, the eye should not leave a circle of this radius
targetMargin = 1; %the margin around the target which indicates a successful saccade

fineFixationTime = 0.5 * timeDilation;
stimulusDisplayTime = 0.4 * timeDilation; %how much display before cueing saccade
saccadeReactionTime = 0.00 * timeDilation; % min time after stimulation off before cueing saccade
saccadeWindowTime = 0.5 * timeDilation; %saccades made outside this window not accepted
saccadeTransitTime = 0.15 * timeDilation; % how long a saccade has to make it to the target

goodTrialTones = [750 0.2 0.9];
goodTrialTimeout = 0;
badTrialTones = repmat([500 0.1 0.9 0 0.1 0], 1, 5);
badTrialTimeout = 2;

require(setupEyelinkExperiment(), @runExperiment);
    function runExperiment(details)
        for i = 1:10
            doTrial(details);
        end
    end

    function doTrial(details)
        
        [main, canvas, events] = mainLoop(details);

        %-----stimulus components----

        fixation = FilledDisk(fixationLocation, 0.1, details.blackIndex);
        canvas.add(fixation);

        stimulus = MoviePlayer(patch);
        canvas.add(stimulus);

        %----- visible state and gaze indicator (development feedback) ----
        state = Text([-5 -5], '', [0 0 details.whiteIndex]);
        canvas.add(state);
        state.setVisible(1);

        gaze = FilledDisk([0 0], 0.1, [details.whiteIndex 0 0]);
        canvas.add(gaze);
        gaze.setVisible(1);
        events.add(UpdateTrigger(@(x, y, t) gaze.setLoc([x y])));

        outlines = TriggerDrawer(events);
        canvas.add(outlines);
        outlines.setVisible(1);
        %{
        %}
        %----- across-state variables -----
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

        function waitingForFixation(x, y, t)
            fixation.setVisible(1);

            nearTrigger.set(fixation.loc(), grossFixationCriterion, @settlingFixation);
            farTrigger.unset();
            timeTrigger.unset();
        end

        function settlingFixation(x, y, t)
            nearTrigger.unset();
            farTrigger.set([x y], grossFixationCriterion, @waitingForFixation);
            timeTrigger.set(t + fixationSettlingTime, @holdingFixation);
        end

        function holdingFixation(x, y, t)
            observedFixation = [x, y];

            nearTrigger.unset();
            farTrigger.set(observedFixation, fineFixationCriterion, @waitingForFixation);
            timeTrigger.set(t + fineFixationTime, @showStimulus);
        end

        function showStimulus(x, y, t)
            stimulus.setVisible(1);
            stimulusOnset = t;

            nearTrigger.unset();
            farTrigger.set(observedFixation, fineFixationCriterion, @brokenFixation);
            timeTrigger.set(t + stimulusDisplayTime, @cueSaccade); %should be timed on screen flip instead, no?
        end

        function cueSaccade(x, y, t)
            fixation.setVisible(0);

            nearTrigger.unset();
            farTrigger.set(observedFixation, fineFixationCriterion, @brokenFixation);
            timeTrigger.set(t + saccadeReactionTime, @awaitSaccade);
        end

        function awaitSaccade(x, y, t)
            nearTrigger.unset();
            timeTrigger.set(t + saccadeWindowTime, @failedSaccade);
            farTrigger.set(observedFixation, fineFixationCriterion, @saccadeTransit);
        end

        function saccadeTransit(x, y, t)
            insideTrigger.set(stimulus, targetMargin, @completeTrial);
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + saccadeTransitTime, @targetNotReached);
        end

        function completeTrial(x, y, t)
            insideTrigger.unset();
            nearTrigger.unset();
            farTrigger.unset();
            
            %spin on waitFinished until trial is over
            timeTrigger.set(0, @waitFinished);
        end
        
        function waitFinished(x, y, t) 
            if ~stimulus.visible()
                main.stop();
                goodFeedback();
            end
        end

        function targetNotReached(x, y, t)
            insideTrigger.unset();
            badTrial(x, y, t);
        end

        function failedSaccade(x, y, t)
            badTrial(x, y, t);
        end

        function brokenFixation(x, y, t)
            badTrial(x, y, t);
        end

        function badTrial(x, y, t)
            %clear screen
            stimulus.setVisible(0);
            fixation.setVisible(0);

            %give feedback at next refresh
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + details.cal.interval, @finishBadTrial);
        end

        function finishBadTrial(x, y, t)
            main.stop();
            badFeedback();
        end

        function goodFeedback
            play(tones(goodTrialTones)); %done on the fly to save memory -- there will be many trial objects
            pause(goodTrialTimeout)
        end

        function badFeedback
            play(tones(badTrialTones));
            pause(badTrialTimeout);
        end

    end
end