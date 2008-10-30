%An object is created to store data for each 'run' of an experiment.
function this = ExperimentRun(varargin)

err = [];
trials = [];
startDate = [];
description = '';
caller = [];
params = struct();

%the edf-file logs each trial individually, so we don't need to log
%them all. So this is a private variable and not a property.
trialsDone_ = {};

persistent init__;
this = inherit( Identifiable(), autoobject(varargin{:}));

if ~isfield(params, 'input')
    params.input = struct('keyboard', KeyboardInput(), 'mouse', MouseInput(), 'eyes', EyelinkInput());
end

    function done = getTrialsDone
        done = trialsDone_;
    end

    function run(varargin)
        params = namedargs(params, varargin{:});
        startDate = clock();

        %experimentRun params get to know information about the
        %environment...
        params = require ...
            ( params ...
            , @clearset ...
            , openLog() ...
            , getScreen() ...
            , @initInput ...
            , logEnclosed('EXPERIMENT_RUN %s', this.getId())...
            , @doRun ...
            );

        function par = doRun(par)
            params = par; %to log initialization information
            e = [];
            if isfield(trials, 'start')
                trials.start();
            end
            try
                dump(this, params.log, 'beforeRun');

                %I used to have it so that experiments
                %were queriable for if they had 
                %a next trial, but it's easier to just return an empty when
                %you're done.
                while ~isfield(trials, 'hasNext') || trials.hasNext()
                    trial = trials.next(params);
                    if isempty(trial)
                        break;
                    end
                    result = require(initparams(params), logEnclosed('TRIAL'), @runTrial);
                    if isfield(result, 'abort') && result.abort
                        break;
                    end
                    if isfield(result, 'err') && ~isempty(result.err);
                        rethrow(result.err);
                    end
                end
            catch
                e = lasterror; %we still want to store the trials done
            end

            function result = runTrial(params)
                
                %no exception handling around dump: if there's a
                %problem with dumping data, end the experiment,
                %please
                
                %we dump the trial structure BEFOREHAND to save the initial
                %state, including any random number seeds etc.
                dump(trial, params.log);

                newParams = params;
                try
                    [newParams, result] = trial.run(params);
                    %%%PERF NOTE the simple exit from run() takes for-ever... 

                    %Strip out unchanging stuff from the trial
                    %parameters.
                    for i = fieldnames(newParams)'
                        if isfield(params, i{1}) && isequalwithequalnans(newParams.(i{1}), params.(i{1}))
                            newParams = rmfield(newParams, i{1});
                        end
                    end

                catch
                    e = lasterror;
                    result.err = e;
                end

                %anything the trial produces should wind up in the 'result'
                %structure.
                dump(newParams, params.log, 'params');
                dump(result, params.log);

                if ~isfield(result, 'err') || isempty(result.err)
                    trials.result(trial, result);
                end
            end

            %finally dump information about this run
            dump(this, params.log, 'afterRun');

            if ~isempty(e)
                rethrow(e); %rethrow errors after logging
            end
        end

    end

    function [release, params] = clearset(params)
        release = @noop;
    end

    function [release, par, next] = initInput(par)
        %initialize the input structure in the trial params.
        s = struct2cell(par.input);
        s = cellfun(@(s) s.init, s, 'UniformOutput', 0);
        i = joinResource(s{:});
        [release, par, next] = i(par);
    end
end