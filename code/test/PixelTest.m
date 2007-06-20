function PixelTest(varargin)
    %visual confirmation that the sprite player and movie player paint
    %correctly to pixels. Also, should confirm that they map correctly to
    %frames.
    
    defaults = struct ...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 0  ...
        , 'requireCalibration', 0 ...
        , 'density', 0.5 ...
        );
    
    params = namedargs(defaults, varargin{:});
    
    require(setupEyelinkExperiment(params), @runDemo);
    function runDemo(params)
        %a patch, that makes pixel changes visible, and superimposes so
        %that the center is gray...
        patch1 = TestGrating('size', [1 1 2], 'spacing', [4 4 60], 'center', [-0.5 -0.5 0]);
        patch2 = TestGrating('size', [1 1 2], 'spacing', [4 4 60], 'center', [0.5 0.5 0]);
        rect1 = FilledRect([0 -1 1 0], 0);
        rect2 = FilledRect([-1 0 0 1], 0);
        bar1 = FilledBar('color', params.blackIndex, 'X', 2+sqrt(2)/2,  'Y', 0, 'angle', 135, 'width', 1, 'length', 3+4*sqrt(2), 'visible', 1);
        bar2 = FilledBar('color', params.whiteIndex, 'X', -2-sqrt(2)/2, 'Y', 0,   'angle', 45,  'width', 1, 'length', 3+4*sqrt(2), 'visible', 1);
        
        %we need a movie player, that fires off once a second.
        movie = MoviePlayer(patch1);
        process = IntervalProcess('dt', 4);
        sprites = SpritePlayer(patch2, process);
        
        %start playing at time 1 second, alternating the sprite with the played
        %movies.
        
        startTrigger = UpdateTrigger(@startPlaying)
        function startPlaying(x, y, t, next)
            %the movie starts playing now; we grab the onset.
            %Since we are instructing the movie player to show its first
            %frame on the next refresh, we then tell the sprite player to
            %play so that its stimulus onset is at the same time as the
            %movie player's.
            onset = movie.setVisible(1, next);
            spriteTime = (onset - next)
            process.setT(spriteTime);
            
            rect1.setVisible(1);
            rect2.setVisible(1);
            
            %The sprite player should start now also, onset
            %aligned with the movie player's onset...
            
            % Now we arringe it so that the movi player should repeat the
            % movie 2 seconds later -- aligned with the sprite player,
            % should be.
            
            % Note the 0.5 frame offset - the time trigger only triggers
            % AFTER a transition is past, not the the most appropriate
            % approximation to the transition. Be careful of this sort of
            % thing. Also notice in teh case of skipped frames -- the movie
            % player REALLY MEANS go at the next refresh, and not 'closest
            % to when I tell it to.' This is a major difference between the movie
            % player and hte sprite player.
            % The other major difference is that the sprite player works by
            % counting movies, while the movie player works by counting 
            movieTrigger.set(t + 4 - params.cal.interval * 0.5, @playMovie);
            offTrigger.set(t + 2 - params.cal.interval * 0.5, @rectsOff);
            startTrigger.unset();
        end
        
        movieTrigger = TimeTrigger(Inf, @playMovie, 0);
        function playMovie(x, y, t, next)
            movie.setVisible(1, next);
            rect1.setVisible(1);
            rect2.setVisible(1);
            movieTrigger.set(t + 4, @playMovie);
        end
        
        offTrigger = TimeTrigger(Inf, @rectsOff, 0);
        function rectsOff(x, y, t, next)
            rect1.setVisible(0);
            rect2.setVisible(0);
            offTrigger.set(t + 4, @rectsOff, 0);
        end

        main = mainLoop ...
            ( {bar1, bar2, rect1, rect2, movie, sprites} ...
            , {startTrigger, movieTrigger, offTrigger} ...
            );
        
        main.go(params);
        
    end

    function this = IntervalProcess(varargin)
        %a simple sprite process. Show the sprite in the same place every
        %dt seconds.
        x = 0;
        y = 0;
        t = 0;
        angle = 0;
        color = [0.5 0.5 0.5];
        dt = 1;
        
        this = finalize(inherit(autoprops(varargin{:}), automethods));
        
        function [xx, yy, tt, aa, cc] = next();
            xx = x;
            yy = y;
            tt = t;
            aa = angle;
            cc = color;
            t = t + dt;
        end
    end
end