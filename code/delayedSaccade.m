function delayedSaccade
%a gaze-contingent display using a trigger driven state-machine programming.

patch = ApparentMotion(...
    'primitive', CauchyBar('size', [0.5 1 0.05], 'velocity', 10),...
    'dx', 1, 'dt', 0.1, 'n', 10, 'center', [0 5 0]);

grossFixationCriterion = 3;
fixationSettlingTime = 0.35;
fineFixationCriterion = 1;
fineFixationTime = 0.15;
stimulusDisplayTime = 0.4; %how much display before cueing saccade
saccadeReactionTime = 0.2; % min time after stimulation off before cueing saccade
saccadeWindowTime = 0.2; %saccades made outside this window not accepted
saccadeTransitTime = 0.15; % how long a saccade has to make it to the target
totalStimulusTime = 2; % total time from stimulus onset to end of trial

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
        
        %----- visible gaze indicator
        gaze = FilledDisk([0 0], 0.1, [255 0 0]);
        canvas.add(gaze);
        gaze.setVisible(1);
        events.add(UpdateTrigger(@(x, y, t) gaze.setLoc([x y])));
        %-----
        
        %----- across-state variables -----
        stimulusOnsetTime = 0;
        observedFixation = [0, 0];
        go = 0;
        
        startStateMachine(@waitingForFixation);
        
        %----- state machine transitions -----
        
        function waitingForFixation(x, y, t)
            fixation.setVisible(1);
            
            stateTransitions(...
                @NearTrigger, {fixation, grossFixationCriterion}, @settlingFixation...
                );
        end
    
        function settlingFixation(x, y, t)
            stateTransitions(...
                @FarTrigger, {FilledDisk([x, y], 0, 0), grossFixationCriterion}, @waitingForFixation,...
                @TimeTrigger, {t + fixationSettlingTime}, @holdingFixation...
                );
        end
        
        function holdingFixation(x, y, t)
            observedFixation = [x, y];
            
            stateTransitions(...
                @FarTrigger, {FilledDisk(observedFixation, 0, 0), fineFixationCriterion}, @waitingForFixation,...
                @TimeTrigger, {t + fineFixationTime}, @showStimulus...
                );
        end
            
        function showStimulus(x, y, t)
            stimulus.setVisible(1);
            stimulusOnset = t;
            
            stateTransitions(...
                @FarTrigger, {filledDisk(observedFixation, 0, 0), 1}, @brokenFixation,...
                @TimeTrigger, {t + stimulusDisplayTime}, @cueSaccade... %should be timed on screen flip instead, no?
                );
        end
        
        function cueSaccade(x, y, t)
            fixation.setVisible(0);
            
            stateTransitions(...
                @TimeTrigger, {t + saccadeReactionTime}, @awaitSaccade,...
                @FarTrigger, {FilledDisk(observedFixation, 0, 0), fineFixationCriterion}, @waitSaccade...
                );
        end
        
        function awaitSaccade(x, y, t)
            stateTransitions(...
                @TimeTrigger, {t + saccadeWindowTime}, @failedSaccade,...
                @FarTrigger, {FilledDisk(observedFixation, 0, 0), fineFixationCriterion}, @saccadeTransit...
                );
        end
        
        function saccadeTransit(x, y, t)
            stateTransitions(...
                @InsideTrigger, {target}, @completeTrial,...
                @TimeTrigger, {t + saccadeTransitTime}, @failedSaccade...
                );
        end
        
        function completeTrial(x, y, t)
            stateTransitions(...
                @TimeTrigger, {stimulusOnsetTime + stimulusDisplayTime}, @stop);
        end
        
        function failedSaccade(x, y, t)
            stop();
        end
            
        function brokenFixation(x, y, t)
            disp('broken fixation!');
            stop();
        end
        
        function stop
            go = 0;
        end
        
        %----- state machine implementation -----
        
        function startStateMachine(initfn)
            stateTransitions(...
                @UpdateTrigger, {}, initfn);
            
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
                events.draw(screenDetails.window, toPixels);
                
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
                    canvas.update();
                end
                lastVBL = VBL;
            end
        end
        
        function stateTransitions(varargin)
            %triplets of arguments give trigger constructors, arguments,
            %and triggered functions.
            
            %Add each trigger, with given arguments. But for state machine
            %simulation we need to remove all
            %triggers from a state as soon as one is removed--so we wrap
            %the triggered functions to do this.
            
            v = reshape(varargin, 3, []);
            
            toRemove = cell(1, size(v, 2));
            transitionFlag = 0; %to ensure only one transition is taken
            i = 0;
            for trans = v %each column is a transition
                i = i + 1; %oh for Python's enumerate() generator...
                toRemove{i} = transitionTrigger(trans{:}); %make the trigger
                events.add(toRemove{i});
            end
            
            function trigger = transitionTrigger(constructor, args, fn)
                %make a trigger that produces a state transition
                trigger = constructor(args{:}, transitionWrapper(fn));
                
                function r = transitionWrapper(f)
                    %removes triggers from the current state before
                    %setting up the new state
                    
                    r = @doTransition;
                    function doTransition(x, y, t)
                        %sometimes two transition criteria will be met on
                        %the same update. We use the flag to exclude all
                        %but the first transition.
                        if ~transitionFlag
                            cellfun(events.remove, toRemove);
                            f(x, y, t);
                            transitionFlag = 1;
                        else
                            disp huh
                        end
                    end
                end
            end
        end
        
        
    end

end