function this = Experiment(varargin)
%The constructor for an Experiment.
%It takes the following named arguments in its constructor:
%
% 'trials', the trial generator (defaults to an instance of ShuffledTrials)
% 'groups', the number of groups to run (default 10)
% 'trialspergroup', the number of trials per group (there is a rest period after
%           each group).
% 'subject', the subject initials (empty means query at runtime)
%
% Any other named arguments are stuffed into the 'params' property and will
% be passed down into the Eyelink and Screen setup routines.
caller = getversion(2);

defaults = namedargs(...
    'trials', ShuffledTrials()...
    ,'subject', ''...
    ,'filename','__auto__'...
    ,'runs', {} ...
    ,'description', ''...
    ,'caller', caller...
    ,'params.logfile', '__auto__'...
    );

%note the Experiment object is not dumped to the edf-file, only the
%ExperimentRun object.

this = Object(...
    Identifiable()...
    , propertiesfromdefaults(defaults, 'params', varargin{:})...
    , public(@run)...
    );

    function run
        if isempty(this.subject)
            this.subject = input('Enter subject initials: ', 's');
        end

        if ~isvarname(this.subject)
            error('Experiment:invalidInput','Please use only letters and numbers in subject identifiers.');
        end

        if isequal(this.filename, '__auto__')
            fname = this.caller.function;
            if ~isvarname(fname)
                error('Experiment:badCallerName'...
                    ,'Caller name %s does not make a good filename.'...
                    , fname);
            end
            this.filename = sprintf('%s-%04d-%02d-%02d__%02d-%02d-%02d-%s.mat',...
                this.subject, floor(clock), fname);
        end

        if isequal(this.params.logfile, '__auto__')
            this.params.logfile = regexprep(this.filename, '\.mat()$|(.)$', '$1.log');
        end

        %TODO: perhaps see if there's a per-subject config?

        %an total experiment can have many runs. Each run will be saved.
        theRun = ExperimentRun(this.params, 'trials', this.trials, 'subject', this.subject, 'description', this.description, 'caller', this.caller);
        e = [];
        try
            theRun.run();
        catch
            theRun.err = lasterror;
        end
        
        this.runs{end+1} = theRun;

        %now save ourself. Since we overwrite, it is prudent to write
        %to a temp file first.
        if(~isempty(this.filename))
            t = tempname;
            disp( sprintf('writing to temp file %s', t));
            save(t, 'this');
            finalfile = fullfile(env('datadir'), this.filename);
            movefile([t '.mat'], finalfile);
            disp( sprintf('saved to %s', finalfile) );
        end

        %if there was an error, report it after saving
        if ~isempty(theRun.err)
            warning('the run stopped with an error: %s', theRun.err.identifier)
            stacktrace(theRun.err);
        end
    end

%An object is created to store data for each 'run' of an experiment.
    function this = ExperimentRun(varargin)

        defaults = namedargs(...
             'err', []...
            ,'trials', []...
            ,'startDate', []...
            );

        %the edf-file logs each trial individually, so we don't need to log
        %them all. So this is a private variable and not a property.
        trialsDone_ = {};
        
        this = Object(...
            Identifiable()...
            ,propertiesfromdefaults(defaults, 'params', varargin{:})...
            ,public(@run)...
            );
        
        function done = getTrialsDone
            done = trialsDone_;
        end

        function run()
            this.startDate = clock();

            %experimentRun params get to know information about the
            %environment...
            this.params = require(...
                openLog(this.params),...
                setupEyelinkExperiment(),...
                logEnclosed('EXPERIMENT_RUN %s', this.id),...
                @doRun);
            
            function params = doRun(params)
                this.params = params; %to log initialization information

                e = [];
                try
                    dump(this, params.log, 'beforeRun');
                    
                    while this.trials.hasNext()
                        next = this.trials.next;
                        trial = next(params);
                        
                        %handle keyboard exceptions here?
                        %I forget why I needed ID. It isn't referenced in
                        %the analysis I have.
                        %require(initparams(params), logEnclosed('TRIAL %s', trial.getId()), @runTrial);
                        result = require(initparams(params), logEnclosed('TRIAL'), @runTrial);
                        if isfield(result, 'abort') && result.abort
                            break;
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
                        
                        %Strip out unchanging stuff form the trial
                        %parameters.
                        for i = fieldnames(newParams)'
                            if isfield(params, i{1}) && isequalwithequalnans(newParams.(i{1}), params.(i{1}))
                                newParams = rmfield(newParams, i{1});
                            end
                        end
                        
                    catch
                        result.err = lasterror;
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
    end %-----ExperimentRun-----
end