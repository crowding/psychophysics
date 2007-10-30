function this = CircleInterpolationTrial(varargin)

%A circular motion with multiple spokes is generated; it is played
%for a short time and then the subject responds with a left or right
%answer. No eye movement tracking in this trial.

%all the visual stimulus is determined by a motion process
%and a Patch.



motion = CircularMotionProcess ...
    ( 'radius', 10 ...
    , 'n', 3 ...
    , 't', 1 ...
    , 'phase', 0 ...
    , 'dt', 0.15 ...
    , 'dphase', 0.75 / 10 ... %dx = 0.75...
    , 'angle', 90 ...
    , 'color', [0.5;0.5;0.5] ...
    );

patch = CauchyPatch...
    ( 'velocity', subsref(motion.getDphase()*motion.getRadius()/motion.getDt(), substruct('()', {1})) ...
    , 'size', [0.5 0.75 0.1]...
    );

%use this to control inter-trial interval
trialStart = 0;

%these parameters say when to show the cue.
cueOnset = 1;
fixationPointSize = 0.1;
fixationPointShift = 0.05;
fixationPointShiftPhase = 0; %must specify this manually.
fixationPointShiftDuration = 0.1;
    
this = autoobject(varargin{:});

%------ methods ------
    function [params, result] = run(params)
        interval = params.cal.interval; %screen refresh interval
        
        motion.reset();
        
        result = struct('success', 0, 'direction', NaN);

        function stopExperiment(s)
            main.stop();
            result.endTime = s.t;
            result.abort = 1;
            result.success = 0;
            result.direction = NaN;
        end

        sprites = SpritePlayer(patch, motion);

        fixationPoint = FilledDisk([0 0], 0.1, params.blackIndex, 'visible', 1);

        timer = RefreshTrigger();
        
        keydown = KeyDown();
        keydown.set(@stopExperiment, 'q');
        keydown.set(@ccwResponse, 'z');
        keydown.set(@cwResponse, 'x');
        keydown.set(@skip, 'space');
        
        main = mainLoop ...
            ( 'graphics', {sprites, fixationPoint} ...
            , 'triggers', {timer} ...
            , 'keyboard', {keydown} ...
            );

        %event handler functions
        
        function isi(s)
            %wait out the inter-stimulus interval
            timer.set(@start, round(s.refresh + (trialStart - s.next) / interval));
        end
        
        function start(s)
            sprites.setVisible(s.next); %onset recorded here...
            cueTime = cueOnset
            stimTime = motion.getT()
            timer.set(@showCue, s.refresh + cueOnset / interval);
         end
        
        function showCue(s)
            fixationPoint.setLoc(fixationPoint.getLoc() ...
                + [cos(fixationPointShiftPhase) -sin(fixationPointShiftPhase)] * fixationPointShift);
            timer.set(@resetCue, round(s.refresh + fixationPointShiftDuration / interval));
        end
        
        function resetCue(s)
            fixationPoint.setLoc([0 0]);
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
            
        function finish(s);
            fixationPoint.setVisible(0);
            sprites.setVisible(0);
            result.endTime = s.t;
            timer.set(main.stop, s.refresh + 1);
        end

        timer.set(@isi, 0);
        params = main.go(params);
    end
end
