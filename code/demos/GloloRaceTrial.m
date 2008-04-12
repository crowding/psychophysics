function this = GloloRaceTrial(varargin)

    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = 0;
        
        graphics = arrayfun(@element, 0:10, 'UniformOutput', 0);
        function player = element(i)
            motion = SimpleMotionProcess...
                ('angle', 0 ...
                , 'dt', 0.1 ...
                , 'dx', [1 0] ...
                , 'onset', 0.1 ...
                , 'origin', [-10 2*i-10] ...
                , 'color', [0.5 0.5 0.5] ...
                );

            patch = CauchyPatch...
                ( 'velocity', 10 ... %velocity of peak spatial frequency
                , 'size', [0.5 0.5 0.05]... %half wavelength of peak spatial frequency in x; sigma of gaussian envelopes in y and t
                , 'order', 4 ... %order of cauchy function
                );

            player = SpritePlayer ...
                ( 'patch', patch ...
                , 'process', motion ...
                );
        end

        duration = 2;
        isi = 1;
        
        trigger = Trigger();
        main = mainLoop ...
            ( 'graphics', graphics ...
            , 'triggers', {trigger} ...
            , 'input', {params.input.keyboard} ...
            );
            
        trigger.singleshot(atLeast('next', 0), @beginMotion);
        trigger.panic(keyIsDown('q'), @stop);

        interval = params.cal.interval;

        main.go(params);
        
        function beginMotion(k)
            for g = 1:numel(graphics)
                graphics{g}.setVisible(1, k.next);
            end
            trigger.singleshot(atLeast('next', k.next + duration - 0.5*interval), @stopMotion);
        end
        
        function stopMotion(k)
            for g = 1:numel(graphics)
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