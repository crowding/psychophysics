function this = ConcentricAdjustmentPeriodicTrial(varargin)
    % Wait for fixation (or keypresses to indicate fixation.)
    % Show a motion stimulus on the screen. Wait for knob turns or
    % keypresses that adjust some parameter of the motion. 
    %
    % When adjustment is called for, hide the motion stimulus, reconfigure
    % while screen blank, and show again after some delay.

    %speed bodges. With these persistent declarations we have to assume
    %this object is a singleton. Oh god.
    persistent fixation;
    persistent motion;
    persistent reconfigureFn;
    persistent extra;
    
    %The two objects on screen.
    fixation = FilledDisk('loc', [0, 0], 'radius', 0.15, 'color', [0 0 0], 'visible', 0);
    motion = CauchySpritePlayer('process', CircularCauchyMotion());

    %Parameters that we use for configuring the stimulus.
    extra = struct...
            ( 'r', 10 ...
            , 'globalVScalar', 0.75 ...
            , 'tf', 10 ...
            , 'wavelengthScalar', .075 ...
            , 'dt', 0.1 ...
            , 'widthScalar', 0.075 ...
            , 'durationScalar', 2/3 ...
            , 'nTargets', 10 ...
            , 'phase', 0 ...
            , 'globalDirection', 1 ...
            , 'localDirection', -1 ...
            , 'color', [0.5;0.5;0.5] ...
            , 'directionContrast', 1 ...
            , 'nStrokes', 5 ... 
            );
            
    %a function that reaches in and rearranges the
    %motion during adjustment. The arguments are the previous and current
    %values of the latent variable.
    
    parameter = 'extra.nTargets';
    parameterValues = [4 5 6 7 8 9 11 13 15 17 19 22 26 30];
    parameterIndex = 1;
    knobDirection = 1;
    reconfigureFn = @configureParameter; 
    
    useAudio = 1; %whether to use audio feedback.
    adjustmentSound = 'Bottle'; %play a click when adjustment threshold is reached.
    adjustmentLimitSound = 'Morse'; %and a sound when bumping into the adjustment limit.
    acceptSound = 'Purr';
    rejectSound = 'Basso';
    abortSound = 'buzz';
    transparentSound = 'Hero';
    
    useEyes = 1; %whether to use eye tracking.
    fixationStartWindow = 3; %this much radius for starting fixation
    fixationSettle = 0.3; %allow this long for settling fixation.
    fixationWindow = 1.5; %subject must fixate this close.
    
    useKnob = 1; %use the knob for input...
    knobDivider = 5; %How many notches of knob turn makes an adjustment of stimulus.
    
    stimulusPeriod = 1; %How often the triger to start motion fires.
    motionOnset = 0.1;  %the motion inset.
    motionReconfigure = 0.9; %How often the trigger to reconfigure fires.

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    function [params, results] = run(params) %#ok
        
        trigger = Trigger;
        key = KeyDown();
        results= struct();
        
        hasShown = 0;
        hasAdjusted = 0;
                
        input = {params.input.keyboard};
        if useEyes
            input = [input {params.input.eyes EyeVelocityFilter}];
        end
            
        if useKnob
            input = [input {params.input.knob}];
        end

        if useAudio
            input = [input {params.input.audioout}];
            audio = params.input.audioout;
        end
        
        if isempty(parameterIndex)
            parameterIndex = randsample(numel(parameterValues),1);
        end
        
        main = mainLoop ...
                ( 'input', input ...
                , 'graphics', {fixation, motion} ...
                , 'triggers', {trigger key} ...
                );

%% how to start: configure the stimulus the first time.
        trigger.singleshot(atLeast('refresh', -Inf), @reconfigure);
        trigger.singleshot(atLeast('refresh', 2), @notFixated);
    
%%      We maintain two states, an "is motion ready" state and an "is
%%      fixation ready" state. When either transitions to one and the other
%%      is already 1, set the "start motion" trigger. When either
%%      transitions to zero, delete the "start motion" trigger and clear
%%      its handle.
    
        isFixated = 0;
        isMotionReady = 0;

        function notFixated(~)
            isFixated = 0;
            fixation.setVisible(1);
            fixation.setRadius(0.12);
            %fixation.setColor([255;0;0]);
            motion.setVisible(0);
            if (useEyes)
                trigger.first( circularWindowEnter('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @settleFixation, 'eyeFt');
            else
%                trigger.singleshot( keyIsDown('space'), @settleFixation);
                trigger.singleshot( always(), @settleFixation );
            end
        end
        
        function settleFixation(k)
            fixation.setRadius(0.11);
            if useEyes
                trigger.first ...
                    ( atLeast('eyeFt', k.triggerTime + fixationSettle), @fixated, 'eyeFt' ...
                    , circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationStartWindow), @notFixated, 'eyeFt' ...
                    );
            else
                trigger.first ...
                    ( atLeast('next', k.keyT + fixationSettle), @fixated, 'next' ...
                    , keyIsDown('tab'), @notFixated, 'keyT' ...
                    );
            end
        end
        
        function fixated(k)
            isFixated = 1;
            fixation.setRadius(0.10);
            if useEyes
                trigger.singleshot(circularWindowExit('eyeFx', 'eyeFy', 'eyeFt', fixation.getLoc, fixationWindow), @notFixated);
            else
                trigger.singleshot(keyIsDown('tab'), @notFixated);
            end

            if (isMotionReady)
                trigger.singleshot(atLeast('next', k.next), @startMotion);
            end
        end
        
%%      How to start motion and show it periodically.
        lastShown = -Inf;
        
        function startMotion(k)
            %fixation.setColor([0;0;0]);
            if(done)
                return;
            end
            lastShown = k.triggerValue;
            motion.setVisible(1, k.triggerValue + motionOnset);
            hasShown = 1;
            trigger.singleshot(atLeast('next', k.triggerValue + motionReconfigure), @reconfigure);
        end
        
        function reconfigure(k)
            motion.setVisible(0);
            isMotionReady = 0;
            trigger.singleshot(atLeast('refresh', k.refresh+1), @doReconfigure);
        end
        
        function doReconfigure(k)
            reconfigureFn(parameterValues(parameterIndex - adjustmentDistance), parameterValues(parameterIndex));
            adjustmentDistance = 0;
            
            fprintf(logf, 'BEGIN STIMULUS\n');
            dump(motion, logf, 'stimulus');
            trigger.singleshot(atLeast('refresh', k.refresh+1), @motionReady);
        end
        
        function motionReady(k)
            if (isMotionReady)
                noop;
                return;
            end
                
            isMotionReady = 1;
            if (isFixated)
                trigger.singleshot(atLeast('next', max(lastShown + stimulusPeriod, k.next + eps(k.next))), @startMotion);
            end
        end

                    
%%      Keyboard adjustment

        trigger.panic(keyIsDown('q'), @abort);
        key.set(@adjustUp,'UpArrow');
        key.set(@adjustDown, 'DownArrow');
        key.set(@acceptIfShownAndAdjusted, 'Return');
        key.set(@reject, 'space');
        key.set(@transparent, 'RightGUI');
        key.set(@transparent, 'LeftGUI');
        
        function adjustUp(k)
            if done 
                return;
            end
            changeParameter(k, 1);
            hasAdjusted = 1;
        end
        
        function adjustDown(k)
            if done 
                return;
            end
            changeParameter(k, -1);
            hasAdjusted = 1;
        end
        
%%      Knob adjustment.

        if useKnob
            trigger.multishot(nonZero('knobRotation'), @knobTurned);
            trigger.multishot(nonZero('knobDown'), @acceptIfShownAndAdjusted);
        end
        
        knobCounter = 0;
        
        function knobTurned(k)
            if done 
                return;
            end
            %this is tricky.
            %what we do is count _consecutive_ steps in the same direction.
            
            rot = knobDirection * k.knobRotation;
            
            %Then each time this accumulated distance crosses a multiple of
            %knobDivisor we increment the latent variable correspondingly.
            
            if (knobCounter ~= 0 && sign(rot) ~= sign(knobCounter))
                knobCounter = 0;                
            end
            
            increments = sum( mod( knobCounter + (sign(rot) : sign(rot) : rot), knobDivider) == 0);
            
            knobCounter = knobCounter + rot;
            
            if (increments > 0)
                hasAdjusted = 1;
                changeParameter(k, sign(rot)*increments);
            end
        end
        
%%      What "adjustment" is.
        adjustmentDistance = 0;
        
        function k = changeParameter(k,howMuch)
            newIndex = parameterIndex + howMuch;
            %fixation.setColor([255;0;0]);
            
            if newIndex < 1;
                newIndex = 1;
            end
            if newIndex > numel(parameterValues)
                newIndex = numel(parameterValues);
            end
            
            if useAudio
                if newIndex ~= parameterIndex
                    audio.play(adjustmentSound, k.next + params.screenInterval*4);
                elseif (howMuch ~= 0) && (newIndex == parameterIndex)
                    audio.play(adjustmentLimitSound, k.next + params.screenInterval*4);
                end
            end
            
            adjustmentDistance = adjustmentDistance + newIndex - parameterIndex;
            
            parameterIndex = newIndex;
            k.parameterIndex = newIndex;
            k.parameter = parameter;
            k.parameterValue = parameterValues(parameterIndex);
        end
        
        logf = params.logf;
                
        
%%      how to stop, and return results.
        done = 0;
        function abort(k)
            results = struct('parameter', parameter, 'parameterValue', parameterValues(parameterIndex), 'motion', motion, 'accepted', 0, 'success', 0, 'abort', 1, 'answer', 'abort');
            stop(k, abortSound);
        end
        
        function acceptIfShownAndAdjusted(~)
            if hasShown && hasAdjusted
                done = 1;
                trigger.singleshot(always(), @accept);
            end
        end
        
        function accept(k)
            results = struct('parameter', parameter, 'parameterValue', parameterValues(parameterIndex), 'motion', motion, 'accepted', 1, 'success', 1, 'answer', 'accept');
            stop(k, acceptSound);
        end
        
        function reject(k)
            done = 1;
            results = struct('parameter', parameter, 'parameterValue', parameterValues(parameterIndex), 'motion', motion, 'accepted', 0, 'success', 1, 'answer', 'reject');
            stop(k, rejectSound);
        end
        
        function transparent(k)
            done = 1;
            results = struct('parameter', parameter, 'parameterValue', parameterValues(parameterIndex), 'motion', motion, 'accepted', 0, 'success', 1, 'answer', 'transparent');
            stop(k, transparentSound);
        end
        
        function stop(k, sound)
            %hide objects
            motion.setVisible(0);
            fixation.setVisible(0);
            if useAudio
                [~,endTime] = audio.play(sound);
            else
                endTime = k.next;
            end
            %and stop on the next frame(after a frame has been drawn with
            %blank screen)
            trigger.singleshot(atLeast('next', endTime + 2 * params.screenInterval), main.stop);
        end
        
        main.go(params);
    end

    function configureParameter(~, final)
        this.property__(parameter, final)
        extra.phase = 2*pi*rand(1);
        appearance();
    end

    function appearance()
        %a big function that configures all of the stimulus using fields in "extra".
        
        mot = motion.getProcess();
        mot.setRadius(extra.r);
        mot.setDt(extra.dt);
        mot.setDphase(extra.dt .* extra.globalVScalar .* extra.globalDirection);
        wl = extra.r * extra.wavelengthScalar;
        mot.setWavelength(wl);
        mot.setWidth(extra.r .* extra.widthScalar);
        mot.setDuration(extra.durationScalar .* extra.dt);
        mot.setN(extra.nStrokes - 1);
        
        ph = mod(extra.phase + (0:extra.nTargets-1)/extra.nTargets*2*pi, 2*pi);
        if isfield(extra, 'nVisibleTargets')
            ph = ph(1:extra.nVisibleTargets);
        end
        
        if (extra.localDirection == 0)
            directionContrast = 0;
            localDirection = 1;
        else
            localDirection = sign(extra.localDirection);
            directionContrast = extra.directionContrast;
        end
        
        if abs(directionContrast) ~= 1
            %The ambiguous motion is made up of two opposing motions superimposed,
            %so we have to double and elements (and reduce the contrast)
            %for that onthis.
            ph = reshape(repmat(ph, 2, 1), 1, []);
            mot.setPhase(ph);
            mot.setAngle(mod(ph*180/pi + 90, 360));
            mot.setVelocity(wl .* extra.tf * repmat([1 -1], 1, numel(ph)/2));
            mot.setVelocity(mot.getVelocity() * localDirection);
            ccc = repmat(extra.color / 2 * [1 + directionContrast, 1-directionContrast], 1, numel(ph)/2);
            mot.setColor(ccc);
        else
            mot.setPhase(ph);
            mot.setAngle(mod(ph*180/pi + 90, 360));
            mot.setVelocity(wl .* extra.tf .* sign(directionContrast) .* localDirection);
            mot.setColor(extra.color);
        end
    end
end