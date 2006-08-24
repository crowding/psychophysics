function delayedSaccade()
%a gaze-contingent display using a trigger driven state-machine programming.

timeDilation = 1; %in mousemode, things should be slower.

patch = ApparentMotion(...
    'primitive', CauchyBar('size', [0.5 1 0.05*timeDilation], 'velocity', 10/timeDilation),...
    'dx', 1, 'dt', 0.1*timeDilation, 'n', 10, 'center', [0 5 0*timeDilation]);

goodBeep = audioplayer(MakeBeep(512, 0.2, 8000)*0.99, 8000);
badBeep = audioplayer(repmat([MakeBeep(512, 0.1, 8000) MakeBeep(512, 0.1, 8000)*0]*0.99, 1, 5), 8000);

grossFixationCriterion = 3;
fixationSettlingTime = 0.35;
fineFixationCriterion = 1;
fineFixationTime = 0.5 * timeDilation;
stimulusDisplayTime = 0.4 * timeDilation; %how much display before cueing saccade
saccadeReactionTime = 0.2 * timeDilation; % min time after stimulation off before cueing saccade
saccadeWindowTime = 0.2 * timeDilation; %saccades made outside this window not accepted
saccadeTransitTime = 0.15 * timeDilation; % how long a saccade has to make it to the target
totalStimulusTime = 2 * timeDilation; % total time from stimulus onset to end of trial
badTrialTimeout = 2; %timeout for a bad trial (not dilated)

require(setupEyelinkExperiment(), @runExperiment);
    function runExperiment(details)
        for i = 1:10
            doTrial(details);
        end
    end

    function doTrial(details)
        %---- boilerplate setup -----
    
        [main, canvas, events] = mainLoop(details);
        toPixels = transformToPixels(details.cal);
        
        %-----stimulus construction----
        
        fixation = FilledDisk([0 0], 0.1, details.blackIndex);
        canvas.add(fixation);
        
        stimulus = MoviePlayer(patch);
        canvas.add(stimulus);
        
        %----- visible state and gaze indicator (development feedback) ----
        state = Text([-5 -5], '', [details.whiteIndex 0 0]);       
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
        stimulusOnsetTime = 0;
        observedFixation = [0, 0];
        go = 0;
        
        %triggers we will re-use
        nearTrigger = NearTrigger();
        farTrigger = FarTrigger();
        timeTrigger = TimeTrigger();
        insideTrigger = InsideTrigger();
        
        %-- hack --
        
        events.add(nearTrigger);
        events.add(farTrigger);
        events.add(timeTrigger);
        events.add(insideTrigger);
        
        waitingForFixation(); %enter initial state
        main.go(details);
        
        stimulus.setVisible(0);
        fixation.setVisible(0);
        nearTrigger.unset();
        farTrigger.unset();
        timeTrigger.unset();
        
        %----- state transitions -----
        
        function waitingForFixation(x, y, t)
            state.setText('waitingForFixation');
            fixation.setVisible(1);
            
            nearTrigger.set(fixation.loc(), grossFixationCriterion, @settlingFixation);
            farTrigger.unset();
            timeTrigger.unset();
        end
        
        function settlingFixation(x, y, t)
            state.setText('settlingFixation');
            nearTrigger.unset();
            farTrigger.set([x y], grossFixationCriterion, @waitingForFixation);
            timeTrigger.set(t + fixationSettlingTime, @holdingFixation);
        end
        
        function holdingFixation(x, y, t)
            state.setText('holdingFixation');
            observedFixation = [x, y];
            
            nearTrigger.unset();
            farTrigger.set(observedFixation, fineFixationCriterion, @waitingForFixation);
            timeTrigger.set(t + fineFixationTime, @showStimulus);
        end
            
        function showStimulus(x, y, t)
            state.setText('showStimulus');
            stimulus.setVisible(1);
            stimulusOnset = t;
            
            nearTrigger.unset();
            farTrigger.set(observedFixation, fineFixationCriterion, @brokenFixation);
            timeTrigger.set(stimulusOnset + stimulusDisplayTime, @cueSaccade); %should be timed on screen flip instead, no?
        end
        
        function cueSaccade(x, y, t)
            state.setText('cueSaccade');
            fixation.setVisible(0);
            
            nearTrigger.unset();
            farTrigger.set(observedFixation, fineFixationCriterion, @brokenFixation);
            timeTrigger.set(t + saccadeReactionTime, @awaitSaccade);
        end
        
        function awaitSaccade(x, y, t)
            state.setText('awaitSaccade');
            nearTrigger.unset();
            timeTrigger.set(t + saccadeWindowTime, @failedSaccade);
            farTrigger.set(observedFixation, fineFixationCriterion, @saccadeTransit);
        end
        
        function saccadeTransit(x, y, t)
            state.setText('saccadeTransit');
            insideTrigger.set(stimulus, @completeTrial);
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + saccadeTransitTime, @targetNotReached);
        end
        
        function completeTrial(x, y, t)
            %play(goodBeep);
            state.setText('completeTrial');
            events.remove(insideTrigger); %hack!
            
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + saccadeTransitTime, main.stop);
        end
        
        function targetNotReached(x, y, t)
            state.setText('targetNotReached');
            insideTrigger.unset(); %hack!
            badTrial(x, y, t);
        end
        
        function failedSaccade(x, y, t)
            state.setText('failedSaccade');
            badTrial(x, y, t);
        end
            
        function brokenFixation(x, y, t)
            state.setText('brokenFixation');
            badTrial(x, y, t);
        end
        
        function badTrial(x, y, t)
            %play(badBeep);
            stimulus.setVisible(0);
            fixation.setVisible(0);

            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + badTrialTimeout, main.stop);
        end
        
    end
end