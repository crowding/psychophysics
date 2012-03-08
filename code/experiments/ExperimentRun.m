%An object is created to store data for each 'run' of an experiment.
function this = ExperimentRun(varargin)

%speed bodges. With these we have to assume this object is a singleton. Oh god.

persistent params;

err = [];
trials = [];
startDate = [];
description = '';
caller = [];
params = struct();
inputConstructors = struct();
inputUsed = {};

%the edf-file logs each trial individually, so we don't need to log
%them all. So this is a private variable and not a property.
trialsDone_ = {};
stopSignaled_ = 0;

persistent init__;
this = inherit( Identifiable(), autoobject(varargin{:}));

    function done = getTrialsDone
        done = trialsDone_;
    end

    stopSignaled_ = 0; % a hook to the UI
    function run(varargin)
        stopSignaled_ = 0;

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
                dump(this, params.logf, 'beforeRun');
                
                %I used to have it so that experiments
                %were queriable for if they had 
                %a next trial, but it's easier to just return an empty when
                %you're done.
                while ~stopSignaled_ && (~isfield(trials, 'hasNext') || trials.hasNext())
                    %shitprof get_next_trial
                    trial = trials.next(params);
                    if isempty(trial)
                        break;
                    end
                    %shitprof run_next_trial
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
                dump(trial, params.logf);

                oldLog  = params.log;
                %%as a speed kludge,
                %%log into memory for the duration of the trial.
                %[push, readout] = linkedlist(2);
                %params.log = @(s, varargin)push(sprintf([s '\n'], varargin{:}));
                
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

                %params.log = oldLog;
                %params.log('%s', readout());
                
                %anything the trial produces should wind up in the 'result'
                %structure.
                dump(newParams, params.logf, 'params');
                dump(result, params.logf);
                if ~isfield(result, 'err') || isempty(result.err)
                    trials.result(trial, result);
                end
            end
            %finally dump information about this run
            dump(this, params.logf, 'afterRun');

            if ~isempty(e)
                rethrow(e); %rethrow errors after logging
            end
        end

    end

    function stop()
        stopSignaled_ = 1;
    end

    function [release, params] = clearset(params)
        release = @noop;
    end

    function [release, par, next] = initInput(par)
        %initialize the input structure in the trial params.
        %which initializers...
        for i = inputUsed(:)'
            par.input.(i{1}) = inputConstructors.(i{1})();
        end
        par.input = structfun(@(x)x(), par.inputConstructors, 'UniformOutput', 0);
        s = cellfun(@(name)par.input.(name).init, inputUsed, 'UniformOutput', 0);
        release = @noop;
        next = joinResource(s{:});
    end
end