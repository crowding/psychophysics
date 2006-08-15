function delayedSaccade
%a gaze-contingent display using a trigger driven state-machine programming.

timeDilation = 5; %in mousemode, things should be slower.

patch = ApparentMotion(...
    'primitive', CauchyBar('size', [0.5 1 0.05*timeDilation], 'velocity', 10/timeDilation),...
    'dx', 1, 'dt', 0.1*timeDilation, 'n', 10, 'center', [0 5 0*timeDilation]);

grossFixationCriterion = 3;
fixationSettlingTime = 0.35;
fineFixationCriterion = 1;
fineFixationTime = 0.15 * timeDilation;
stimulusDisplayTime = 0.4 * timeDilation; %how much display before cueing saccade
saccadeReactionTime = 0.2 * timeDilation; % min time after stimulation off before cueing saccade
saccadeWindowTime = 0.2 * timeDilation; %saccades made outside this window not accepted
saccadeTransitTime = 0.15 * timeDilation; % how long a saccade has to make it to the target
totalStimulusTime = 2 * timeDilation; % total time from stimulus onset to end of trial
badTrialTimeout = 2; %timeout for a bad trial (not dilated)

require(@setupEyelinkExperiment, @runExperiment);
    function runExperiment(screenDetails)
        require(highPriority(screenDetails.window), @trials);
        function trials
            for i = 1:10
                doTrial(screenDetails);
            end
        end
    end

    function doTrial(screenDetails)
    
        %---- boilerplate setup -----
        canvas = Drawing(screenDetails.cal, screenDetails.window);
    
        cal = screenDetails.cal;
        toPixels = transformToPixels(cal);
        
        events = EyeEvents(cal, screenDetails.el);
        
        %-----stimulus construction----

        back = Background(screenDetails.gray);
        canvas.add(back);
        back.setVisible(1);
        
        fixation = FilledDisk([0 0], 0.1, screenDetails.black);
        canvas.add(fixation);
        
        stimulus = MoviePlayer(patch);
        canvas.add(stimulus);
        
        %----- visible state and gaze indicator (development feedback) ----
        
        gaze = FilledDisk([0 0], 0.1, [255 0 0]);
        canvas.add(gaze);
        gaze.setVisible(1);
        
        events.add(UpdateTrigger(@(x, y, t) gaze.setLoc([x y])));

        state = DisplayText([-5 -5], '', [255 0 0]);
        canvas.add(state);
        state.setVisible(1);
        
        outlines = TriggerDrawer(events);
        canvas.add(outlines);
        outlines.setVisible(1);
            
        %----- across-state variables -----
        stimulusOnsetTime = 0;
        observedFixation = [0, 0];
        go = 0;
        
        %triggers we will re-use
        nearTrigger = NearTrigger();
        farTrigger = FarTrigger();
        timeTrigger = TimeTrigger();
        
        %-- hack --
        insideTrigger = InsideTrigger(stimulus, @completeTrial);
        
        events.add(nearTrigger);
        events.add(farTrigger);
        events.add(timeTrigger);
        
        startStateMachine(@waitingForFixation);
        
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
            events.add(insideTrigger); %hack!
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + saccadeTransitTime, @targetNotReached);
        end
        
        function completeTrial(x, y, t)
            state.setText('completeTrial');
            events.remove(insideTrigger); %hack!
            
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + saccadeTransitTime, @stop);
        end
        
        function targetNotReached(x, y, t)
            state.setText('targetNotReached');
            events.remove(insideTrigger); %hack!
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
            stimulus.setVisible(0);
            fixation.setVisible(0);

            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.set(t + badTrialTimeout, @stop);
        end
        
        function stop(x, y, t)
            state.setText('stop');
            
            stimulus.setVisible(0);
            fixation.setVisible(0);
            nearTrigger.unset();
            farTrigger.unset();
            timeTrigger.unset();
            
            go = 0;
        end
        
        %----- state machine implementation -----
        
        function startStateMachine(initfn)
            initfn();
            go = 1;
            eventLoop();
        end
        
        function eventLoop();
            frameshit = 0;
            framesmissed = 0;
            lastVBL = -1;
            interval = screenDetails.cal.interval;
            
            while go
                events.update();
                canvas.draw();
                
                [VBL] = Screen('Flip', screenDetails.window);
                frameshit = frameshit + 1;
                %count the number of frames advanced and do the
                %appropriate number of canvas.update()s
                if lastVBL > 0
                    frames = round((VBL - lastVBL) / interval);
                    framesmissed = framesmissed + frames - 1;
                    
                    if frames > 60
                        error('mainLoop:drawing stuck', 'got stuck doing frame updates...');
                    end
                    for i = 1:round((VBL - lastVBL) / interval)
                        %may accumulate error if
                        %interval differs from the actual interval... 
                        %but we're screwed in that case.
                        canvas.update();
                    end
                else
                    canvas.update(); %give one update for the initial frame;
                end
                lastVBL = VBL;
            end
        end
    end
end