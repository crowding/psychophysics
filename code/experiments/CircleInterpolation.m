function CircleInterpolation(varargin)
    params = struct...
        ( 'edfname',    '' ...
        , 'dummy',      1  ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        );
    params = namedargs(params, varargin{:});
    
    require(setupEyelinkExperiment(params), @run)
    function params = run(params)
        e = InterpolationTrialGenerator();
        while (e.hasNext())
            t = e.next(params);
            t.run(params);
        end
    end
end