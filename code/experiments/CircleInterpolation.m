function CircleInterpolation(varargin)
    params = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        );
    params = namedargs(params, varargin{:});

    e = Experiment();
    
    require(setupEyelinkExperiment(params), @run)
    
    function params = run(params)
        e = InterpolationTrialGenerator();
        while (e.hasNext())
            t = e.next(params);
            t.run(params);
        end
    end

    function this = InterpolationTrialGenerator(varargin)
        nDistractors = 1;
        radius = 10;
        dx = 0.75;
        dt = 0.15;
        nBefore = 2;
        nAfter = 2;
        patch = CauchyPatch...
            ( 'velocity', 5 * (round(rand)*2-1) ...
            , 'size', [0.5 0.75 0.1]...
            );
        
        this = finalize(inherit(autoprops(varargin{:}), automethods));
        
        function has = hasNext()
            has = 1;
        end
        
        function trial = next(params)
            %Build a randomly generated circular motion trial.

            %for now, set a bar onset asynchrony and displacement at random. (these
            %will be controlled through adaptive processes soon)
            thisDx = dx * (round(rand())*2 - 1);
            
            barAsynchrony = (rand() - 0.5) * dt;
            barAsynchrony = params.cal.interval * floor(barAsynchrony / params.cal.interval);
            barAsynchrony = 0;
            barDisplacement = (rand()-0.5) * thisDx;
            
            %computed properties
            %onset times of each thing
            onsets = dt + (0:nDistractors-1) * dt / nDistractors;
            %adjust for frame intervals
            onsets = params.cal.interval * floor(onsets / params.cal.interval);

            %phases of each thing
            phases = (rand() + (0:nDistractors-1)/nDistractors)*2*pi;
            phases = phases + rand(1, nDistractors) * pi/nDistractors;
            %phases = rand(1, nDistractors)*2*pi;
            phases = phases(randPerm(length(phases)));
            
            %randomly choose one of the items as the target
            targetIndex = ceil(rand() * nDistractors);

            %set the bar onset asynchrony
            p = patch;
            p.velocity = p.velocity * (round(rand)*2-1);
            
            trial = CircleInterpolationTrial ...
                ( 'dx', thisDx ...
                , 'dt', dt ...
                , 'n', nBefore + nAfter + 1 ...
                , 'onsets', onsets ...
                , 'phases', phases ...
                , 'barPhase', phases(targetIndex) + (nBefore*thisDx + barDisplacement)/radius...
                , 'barOnset', onsets(targetIndex) + nBefore*dt + barAsynchrony ...
                , 'patch', p ...
                );
        end
    end
end