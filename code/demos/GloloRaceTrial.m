function this = GloloRaceTrial(varargin)

    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = 0;
        
        sprites = arrayfun(@element, 0:2, 'UniformOutput', 0);
        function player = element(i)
            motion = SimpleMotionProcess...
                ('angle', 0 ...
                , 'dt', 0.2 ...
                , 'dx', [2 0] ...
                , 'onset', 0.1 ...
                , 'origin', [-10 -8+8*i] ...
                , 'color', [0.5 0.5 0.5] ...
                );

            patch = CauchyPatch...
                ( 'velocity', i*7.5 ... %velocity of peak spatial frequency
                , 'size', [1 1 0.15]... %half wavelength of peak spatial frequency in x; sigma of gaussian envelopes in y and t
                , 'order', 4 ... %order of cauchy function
                );

            player = SpritePlayer ...
                ( 'patch', patch ...
                , 'process', motion ...
                );
        end
        
        bar = FilledBar...
            ( 'angle', 0 ...
            , 'color', 1 ...
            , 'length', 20 ...
            , 'width', 0.1 ...
            , 'x', 9 ...
            , 'y', 0 ...
            );

        duration = 2;
        flash = 1.9;
        flashDuration = 1/60;
        isi = 1;
        
        trigger = Trigger();
        main = mainLoop ...
            ( 'graphics', {sprites{:}, bar} ...
            , 'triggers', {trigger} ...
            , 'input', {params.input.keyboard} ...
            );
            
        trigger.singleshot(atLeast('next', 0), @beginMotion);
        trigger.panic(keyIsDown('q'), @stop);

        interval = params.cal.interval;

        main.go(params);
        
        function beginMotion(k)
            for g = 1:numel(sprites)
                graphics{g}.setVisible(1, k.next);
            end
            trigger.singleshot(atLeast('next', k.next + duration - 0.5*interval), @stopMotion);
            trigger.singleshot(atLeast('next', k.next + duration - 0.5*interval), @showBar);
        end
        
        function showBar(k)
            
        end
        
        function stopMotion(k)
            for g = 1:numel(sprites)
                graphics{g}.setVisible(0);
            end
            trigger.singleshot(atLeast('next', k.next + isi - 0.5*interval), @beginMotion);
        end
        
        function stop(k) %#ok
            main.stop();
        end
        
        function [release, params] = init(params) %for triggering
            release = @noop;
        end
    end
end