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

defaults = struct(...
    'trials', {{}},... %wrap in cells is deliberate - struct() sucks
    'subject', {''},...
    'runs', {{}}...
    );

this = Object(...
    propertiesfromdefaults(defaults, 'params', varargin{:}),...
    public(@run));

%input-dependent default
if isempty(this.trials)
    this.trials = ShuffledTrials(this.params);
end

%----- instance variables -----

    function filename = run
        if isempty(this.subject)
            error('need subject initials'); %need to gather subject infos
        end
        %perhaps query for some subject params?
        
        %an total experiment can have many runs. Each run will be saved.
        theRun = ExperimentRun('trials', this.trials, this.params);
        theRun.run(this.trials);
        this.runs{end+1} = theRun;

        %now save ourself?
        warning('experiment save not implemented');
        
        %if there was an error, report it after saving
        if ~isempty(theRun.err)
            rethrow(theRun.err)
        end
    end



    %An object that stores data for each 'run' of a long experiment.
    function this = ExperimentRun(varargin)
        %The 'trials' parameter is a trial iterator. it generates trials
        %(and might
        %pause, respond to keyboard input, adn so on, which is why it needs
        %params() to run.)
        defaults = struct(...
            'trialsDone', {{}},...
            'err', [],...
            'startDate', []);
        
        this = Object(...
            propertiesfromdefaults(defaults, 'params', varargin{:}),...
            public(@run));
        
        
        function run(trials)
            this.startDate = clock();
            
            this.params = require(setupEyelinkExperiment(this.params), @doRun);
            function params = doRun(params)
                if params.dummy
                    params.timeDilation = 3;
                end
                
                while trials.hasNext()
                  
                    trial = trials.next();
                    
                    e = [];
                    try
                        trial.run(params);
                    catch
                        e = lasterr;
                    end

                    trials.result(trial);
                    
                    try
                        this.trialsDone{end+1} = trial;
                    catch
                        clear Screen
                        this.trialsDone{end+1} = trial;
                    end
                    
                    if ~isempty(e)
                        this.err = e;
                        break;
                    end
                end
                
            end
            
        end
        
    end


end