function params = playDemo(trial, varargin)
    %set up enough to play a trial object in demo mode.
    def = namedOptions...
        ( 'edfname',    '' ...
        , 'skipFrames', 1  ...
        , 'requireCalibration', 0 ...
        , 'hideCursor', 0 ...
        , 'aviout', '' ...
        , 'logfile', '' ...
        , 'inputUsed', defaults('get', 'Experiment', 'inputUsed') ...
        , 'inputConstructors', defaults('get', 'Experiment', 'inputConstructors') ...
        );
    %, 'priority', 0 ...

    if isfield(trial, 'getParams')
        def = namedOptions(struct(), trial.getParams(), def);
    end

    require(namedOptions(def, varargin{:}), getScreen(), openLog(), @initInput, trial.run)
end

function [release, par, next] = initInput(par)
    %initialize the input structure in the trial params.
    %which initializers...
    for i = par.inputUsed(:)'
        par.input.(i{1}) = par.inputConstructors.(i{1})();
    end
    par.input = structfun(@(x)x(), par.inputConstructors, 'UniformOutput', 0);
    s = cellfun(@(name)par.input.(name).init, par.inputUsed, 'UniformOutput', 0);
    release = @noop;
    next = joinResource(s{:});
end