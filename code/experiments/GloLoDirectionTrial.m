function this = GloLoDirectionTrial(varargin)

%A circular motion with multiple spokes is generated; it is played
%for a short time and then the subject responds with a left or right
%answer. No eye movement tracking in this trial.

%all the visual stimulus is determined by a motion process
%and a Patch.

motion = [];
patch = [];

%use this to control inter-trial interval
trialStart = 0;

%these parameters say when to show the cue.
cueOnset = 1;
fixationPointSize = 0.1;
cueSize = 0.1;
cueLocation = [0 0];
cueDuration = 0.1;
cwResponseKey = 'x';
ccwResponseKey = 'z';
knobTurnThreshold = 3;
    
this = autoobject(varargin{:});

%complicated properties take too long especially if deep-cloning
if isempty(motion)
    motion = CircularMotionProcess ...
        ( 'radius', 10 ...
        , 'n', 3 ...
        , 't', 1 ...
        , 'phase', 0 ...
        , 'dt', 0.15 ...
        , 'dphase', 0.75 / 10 ... %dx = 0.75...
        , 'angle', 90 ...
        , 'color', [0.25;0.;0.125] ...
        );
end

if isempty(patch)
    patch = CauchyPatch...
        ( 'velocity', subsref(motion.getDphase()*motion.getRadius()/motion.getDt(), substruct('()', {1})) ...
        , 'size', [0.5 0.75 0.1]...
        );
end

%------ methods ------
    function [params, result] = run(params)
        interval = params.cal.interval; %screen refresh interval
        
        motion.reset();
        
        result = struct('success', 0, 'direction', NaN);

        cwKeyCode = KbName(cwResponseKey);
        ccwKeyCode = KbName(ccwResponseKey);
        
        function stopExperiment(s)
            main.stop();
            result.endTime = s.next;
            result.abort = 1;
            result.success = 0;
            result.direction = NaN;
        end

        sprites = SpritePlayer(patch, motion);

        fixationPoint = FilledDisk([0 0], fixationPointSize, params.blackIndex, 'visible', 1);
        cuePoint = FilledDisk(cueLocation, cueSize, params.blackIndex, 'visible', 0);

        timer = RefreshTrigger();
        
        keydown = KeyDown();
        keydown.set(@stopExperiment, 'q');
        keydown.set(@skip, 'space');
        
        knob = KnobThreshold();
        button = KnobDown();
        button.set(@skip);
        
        input = {params.input.keybaord}
        triggers = {timer, keydown}
        
        if isfield(params.input, 'knob')
            input{end+1} = params.input.knob;
            triggers{end+1} = knob;
            triggers{end+1} = button;
        end
            
        
        main = mainLoop ...
            ( 'graphics', {sprites, fixationPoint, cuePoint} ...
            , 'input', input ...
            , 'triggers', triggers ...
            );

        %event handler functions
        
        function isi(s)
            result.isiWaitStartTime = s.next;
            %wait out the inter-stimulus interval
            timer.set(@start, round(s.refresh + (trialStart - s.next) / interval));
        end
        
        function start(s)
            result.startTime = s.next;
            sprites.setVisible(s.next); %onset recorded here...
            timer.set(@showCue, s.refresh + cueOnset / interval);
         end
        
        function showCue(s)
            cuePoint.setVisible(1);
            timer.set(@resetCue, round(s.refresh + cueDuration / interval));
            knob.set(@cwResponse, s.knobPosition + knobTurnThreshold, @ccwResponse, s.knobPosition - knobTurnThreshold);
            keydown.set(@cwResponse, cwKeyCode);
            keydown.set(@cwResponse, cwKeyCode);
        end
        
        function resetCue(s)
            cuePoint.setVisible(0);
            timer.unset();
        end
        
        function ccwResponse(s)
            result.direction = 1;
            result.success = 1;
            finish(s);
        end
        
        function cwResponse(s)
            result.direction = -1;
            result.success = 1;
            finish(s);
        end
        
        function skip(s);
            result.direction = NaN;
            result.direction = -1;
            finish(s);
        end
            
        function finish(s)
            knob.unset();
            keydown.unset();
            fixationPoint.setVisible(0);
            sprites.setVisible(0);
            result.endTime = s.next;
            timer.set(main.stop, s.refresh + 1);
        end

        timer.set(@isi, 0);
        params = main.go(params);
    end
end