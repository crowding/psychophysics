function SuperpositionTest(varargin)
defaults = struct...
    ( 'edfname',    '' ...
    , 'dummy',      1  ...
    , 'skipFrames', 0  ...
    , 'duration',   20 ...
    , 'interval',   5  ...
    );
params = namedargs(defaults, varargin{:});
% a simple graphics demo that shows a movie.

%setupEyelinkExperiment does everything up to preparing the trial;
%mainLoop.go does everything after.

require(setupEyelinkExperiment(params), @runDemo);
    function runDemo(details)

        patch1 = MoviePlayer(ApparentMotion('primitive', CauchyPatch('velocity', 5, 'size', [1 1 0.2]), 'dx', 2, 'dt', 0.2, 'n', 5, 'center', [-5 0.5 0]));
        patch2 = MoviePlayer(ApparentMotion('primitive', CauchyPatch('velocity', 5, 'size', [1 1 0.2]), 'dx', -2, 'dt', 0.2, 'n', 5, 'center', [5 -0.5 0]));
        
        startTrigger = UpdateTrigger(@start);
        playTrigger = TimeTrigger();
        stopTrigger = TimeTrigger();
        
        main = mainLoop ...
            ( {patch1, patch2} ...
            , {startTrigger, playTrigger, stopTrigger} ...
            );
        
        % ----- the main loop. -----
        details = main.go(details);

        %----- the event handlers functions -----

        function start(x, y, t, next)
            playTrigger.set(t + 5, @play);
            stopTrigger.set(t + 20, main.stop);
            startTrigger.unset();
        end
        
        function play(x, y, t, next)
            disp('playing');
            patch1.setVisible(1);
            patch2.setVisible(1);
            playTrigger.set(t + 5, @play); %play every five seconds
        end
    end
end
