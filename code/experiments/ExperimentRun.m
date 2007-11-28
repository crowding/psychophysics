%An object is created to store data for each 'run' of an experiment.
function this = ExperimentRun(varargin)

err = [];
trials = [];
startDate = [];
params = struct();

%the edf-file logs each trial individually, so we don't need to log
%them all. So this is a private variable and not a property.
trialsDone_ = {};

persistent init__;
this = Object( Identifiable(), autoobject(varargin{:}));

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
            ( openLog(params) ...
            , getScreen() ...
            , getSound() ...
            , @initInput ...
            , logEnclosed('EXPERIMENT_RUN %s', this.getId())...
            , @doRun ...
            );

        function par = doRun(par)
            params = par; %to log initialization information
            checkpoint(Inf);
            e = [];
            try
                dump(this, params.log, 'beforeRun');

                while trials.hasNext()
                    trial = trials.next(params);
                    result = require(checkinit(), initparams(params), logEnclosed('TRIAL'), checkinit(), @runTrial);
                    if isfield(result, 'abort') && result.abort
                        break;
                    end
                    if isfield(result, 'err') && ~isempty(result.err);
                        rethrow(result.err);
                    end
                end
            catch
                e = lasterror; %we still want to store the trials done
                err = e;
            end

            function result = runTrial(params)
                
                newParams = params;
                try
                    checkpoint();
                    [newParams, result] = trial.run(params);
                    checkpoint();
                    %%%PERF NOTE the simple exit from run() takes for-ever... 

                    %Strip out unchanging stuff from the trial
                    %parameters.
                    for i = fieldnames(newParams)'
                        if isfield(params, i{1}) && isequalwithequalnans(newParams.(i{1}), params.(i{1}))
                            newParams = rmfield(newParams, i{1});
                        end
                    end
                    checkpoint();

                catch
                    e = lasterror;
                    result.err = e;
                end
                checkpoint();
                %no exception handling around dump: if there's a
                %problem with dumping data, end the experiment,
                %please
                checkpoint()
                dump(trial, params.log);
                dump(newParams, params.log, 'params');
                dump(result, params.log);
                checkpoint();

                if ~isfield(result, 'err') || isempty(result.err)
                    trials.result(trial, result);
                end
                checkpoint();
            end

            %finally dump information about this run
            dump(this, params.log, 'afterRun');

            if ~isempty(e)
                rethrow(e); %rethrow errors after logging
            end
        end

    end

    function [release, par] = initInput(par)
        %initialize the input structure in the trial params.
        s = struct2cell(par.input);
        s = cellfun(@(s) s.init, s, 'UniformOutput', 0);
        i = joinResource(s{:});
        [release, par] = i(par);
    end
end