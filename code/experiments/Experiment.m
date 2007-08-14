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

defaults = namedargs...
    ( 'trials', ShuffledTrials()...
    , 'subject', ''...
    , 'filename','__auto__'...
    , 'runs', {} ...
    , 'description', ''...
    , 'caller', caller...
    , 'params.logfile', '__auto__'...
    , 'params.hideCursor', 1 ...
    );

params = namedargs(defaults, varargin{:}); %htis is only used for the file check

if isempty(params.subject)
    params.subject = input('Enter subject initials: ', 's');
end

if ~isvarname(params.subject)
    error('Experiment:invalidInput','Please use only letters and numbers in subject identifiers.');
end

%if there is a previous unfinished experiment, load it.
pattern = [params.subject '*' params.caller.function '.mat'];
last = dir(fullfile(env('datadir'),pattern));
if ~isempty(last) && (~isfield(params, 'continuing') || params.continuing)
    last = last(end).name;
    disp (['checking last saved file... ' last]);
    x = load(fullfile(env('datadir'), last));

    if isfield(x.this, 'beginBlock')
        x.this.beginBlock();

        if x.this.hasNext()
            if ~isfield(params, 'continuing');
                answer = '';
                while (~strcmp(answer,'n') || ~strcmp(answer,'y'))
                    answer = input('Continue last session?', 's');
                end
                params.continuing = strcmp(answer, 'y');
                defaults.continuing = defaults.continuing;
            end
            if (params.continuing)
                this = x.this; %the block is begun...
                return;
            end
        end
    end
    x = [];
end

%note the Experiment object is not dumped to the edf-file, only the
%ExperimentRun object.

this = Object(...
    Identifiable()...
    , propertiesfromdefaults(params, 'params', varargin{:})...
    , public(@run)...
    );
    
    function run(params)
        if exist('params', 'var')
            params = namedargs(this.params, params);
            this.params = params;
        else
            params = this.params;
        end

        if isfield(this.trials, 'startBlock')
            this.trials.startBlock(); %IT ARE BEING CALLD TWICE IF CONTINUED
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

	42
	params.logfile
        if isequal(params.logfile, '__auto__')
            this.params.logfile = regexprep(this.filename, '\.mat()$|(.)$', '$1.log');
        end
        
        %TODO: perhaps see if there's a per-subject config?

        %an total experiment can have many runs. Each run will be saved.
        theRun = ExperimentRun...
            ( this.params...
            , 'trials', this.trials...
            , 'subject', this.subject...
            , 'description', this.description...
            , 'caller', this.caller);
        e = [];
        try
            [stat, host] = system('hostname');
            if strfind(host, 'pastorianus')
                switchscreen('videoIn', 2, 'videoOut', 1, 'immediate', 1);
                theRun.run();
            else
                theRun.run();
            end
        catch
            theRun.err = lasterror;
            if strfind(host, 'pastorianus')
                switchscreen('videoIn', 1, 'videoOut', 1, 'immediate', 1);
            end
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
end
