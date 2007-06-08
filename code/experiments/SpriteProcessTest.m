function SpriteProcessTest(varargin)
params = struct...
    ( 'edfname',    '' ...
    , 'dummy',      1  ...
    , 'skipFrames', 0  ...
    , 'duration',   20 ...
    , 'interval',   5  ...
    , 'requireCalibration', 0 ...
    , 'density', 0.5 ...
    );
params = namedargs(params, varargin{:});
% a graphics demo that shows moving objects in the midst of
% background noise.

%setupEyelinkExperiment does everything up to preparing the trial;
%mainLoop.go does everything after.

require(setupEyelinkExperiment(params), @runDemo);
    function runDemo(params)

        %patch = CauchyPatch('velocity', 10, 'size', [1 1.5 0.1]);
        patch = CauchyPatch('velocity', 5, 'size', [0.5 0.75 0.1]);
        
        noise = AnnularDotProcess([0 0 7 12], params.density, 0.5);
        motion = AnnularMotionProcess([0 0 10 10], 0.5, 0.1, 10, 2, 2, 0.5);
        
        gaze = FilledDisk([0 0], 0.1, [0 0 0]);
        
        process = ComboProcess(noise, motion);

        player = SpritePlayer(patch, process);
        
        startTrigger = UpdateTrigger(@start);
        blankColorTrigger = TimeTrigger(Inf, @noop, 0);
        
        main = mainLoop ...
            ( {player, gaze} ...
            , {startTrigger, blankColorTrigger} ...
            );
        
        % ----- the main loop. -----
        params = main.go(params);

        function start(x, y, t, next)
            player.setVisible(1, next);
            gaze.setVisible(1);
            %blankColorTrigger.set(next + 20, @blankColor);
            startTrigger.unset();
        end
        
    end
end
