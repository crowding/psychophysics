function e = CircleInterpolation(varargin)
    params = struct...
        ( 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        );
    params = namedargs(params, varargin{:});
    
    e = Experiment('trials', CircleInterpolationTrialGenerator(), params);
    e.run();
end