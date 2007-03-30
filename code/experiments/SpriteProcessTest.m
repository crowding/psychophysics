function SpriteProcessTest(varargin)
defaults = struct...
    ( 'edfname',    '' ...
    , 'dummy',      1  ...
    , 'skipFrames', 1  ...
    , 'duration',   20 ...
    , 'interval',   5  ...
    );
params = namedargs(defaults, varargin{:});
% a simple graphics demo that shows a movie.

%setupEyelinkExperiment does everything up to preparing the trial;
%mainLoop.go does everything after.

require(setupEyelinkExperiment(params), @runDemo);
    function runDemo(details)

        patch1 = CauchyPatch('velocity', 10, 'size', [1 1.5 0.1]);
        patch2 = CauchyPatch('velocity', -10, 'size', [1 1.5 0.1]);
        
        process1 = DotProcess([-15 -10 15 10], 0.0015);
        process2 = DotProcess([-15 -10 15 10], 0.0015);
        process3 = MotionProcess([-5 -5 5 5], 2, 0.2, 5, 2);
        
        player1 = SpritePlayer(patch1, process1, @noop);
        player2 = SpritePlayer(patch2, process2, @noop);
        player3 = SpritePlayer(patch1, process3.getRight(), @noop);
        player4 = SpritePlayer(patch2, process3.getLeft(), @noop);
        
        startTrigger = UpdateTrigger(@start);
        
        main = mainLoop ...
            ( {player1, player2, player3, player4} ...
            , {startTrigger} ...
            );
        
        % ----- the main loop. -----
        details = main.go(details);

        %----- the event handlers functions -----

        function start(x, y, t, next)
            player1.setVisible(1, next);
            player2.setVisible(1, next);
            startTrigger.unset();
        end
    end
end
