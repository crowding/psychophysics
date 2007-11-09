%An object is created to store data for each 'run' of an experiment.
function this = ExperimentRun(varargin)

defaults = namedargs(...
    'err', []...
    ,'trials', []...
    ,'params.input', struct('keyboard', KeyboardInput(), 'mouse', MouseInput(), 'eyes', EyelinkInput)...
    ,'startDate', []...
    );

%the edf-file logs each trial individually, so we don't need to log
%them all. So this is a private variable and not a property.
trialsDone_ = {};

this = Object...
    ( Identifiable()...
    , propertiesfromdefaults(defaults, 'params', varargin{:})...
    , public(@run)...
    );

    function done = getTrialsDone
        done = trialsDone_;
    end

    function run(params)
        if exist('params', 'var');
            this.params = namedargs(this.params, params);
        end
        this.startDate = clock();

        %experimentRun params get to know information about the
        %environment...
        this.params = require ...
            ( openLog(this.params) ...
            , getScreen() ...
            , getSound() ...
            , @initInput ...
            , logEnclosed('EXPERIMENT_RUN %s', this.id)...
            , @doRun ...
            );

        function params = doRun(params)
            this.params = params; %to log initialization information

            e = [];
            try
                dump(this, params.log, 'beforeRun');

                while this.trials.hasNext()
                    next = this.trials.next;
                    trial = next(params);

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
                this.err = e;
            end

            function result = runTrial(params)
                newParams = params;
                try
                    [newParams, result] = trial.run(params);

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

                %no exception handling around dump: if there's a
                %problem with dumping data, end the experiment,
                %please
                dump(trial, params.log);
                dump(newParams, params.log, 'params');
                dump(result, params.log)

                this.trials.result(trial, result);
            end

            %finally dump information about this run
            this.params = params;
            dump(this, params.log, 'afterRun');

            if ~isempty(e)
                rethrow(e); %rethrow errors after logging
            end
        end

    end

    function [release, params] = initInput(params)
        %initialize the input structure in the trial params.
        s = struct2cell(params.input);
        s = cellfun(@(s) s.init, s, 'UniformOutput', 0);
        i = joinResource(s{:});
        [release, params] = i(params);
    end
end