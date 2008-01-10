function this = Experiment(varargin)
%The constructor for an Experiment.
%It takes the following named arguments in its constructor:
%
% 'trials', the trial generator (defaults to an instance of ShuffledTrials)
% 'subject', the subject initials (empty means query at runtime)
% 'filename', the name of the file to save to (defaults to __auto__ whcih
%             will choose one
% 'description', a textual description of the experiment.
%
% Any other named arguments are stuffed into the 'params' property and will
% be passed down into the Eyelink and Screen setup routines.

trials = Randomizer();
subject = '';
filename = '__auto__';
runs = {{}};
description = '';
caller = getversion(2);

params = namedargs...
        (localExperimentParams()...
        , struct ...
            ( 'logfile', '__auto__'...
            , 'hideCursor', 1 ...
            , 'continuing', 0 ...
            , 'input', struct...
            ( 'keyboard', KeyboardInput()...
            )...
    );

persistent init__;
this = Obj(inherit(Identifiable(), autoobject(varargin{:})));

%{
%if there is a previous unfinished experiment, load it.
pattern = [this.subject '*' this.caller.function '.mat'];
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
%}

%note the Experiment object is not dumped to the edf-file, only the
%ExperimentRun object.

    function setParams(varargin)
        params = namedargs(params, varargin{:});
    end
        
    function run(varargin)
        if isempty(subject)
            subject = input('Enter subject initials: ', 's');
        end
        
        if ~isvarname(subject)
            error('Experiment:invalidInput','Please use only letters and numbers in subject identifiers.');
        end

        params = namedargs(params, varargin{:});

        if isfield(trials, 'startBlock')
            this.trials.startBlock(); %IT IS CALLED TWICE IF CONTINUED?
        end
        
        if isequal(filename, '__auto__')
            fname = caller.function;
            if ~isvarname(fname)
                error('Experiment:badCallerName'...
                    ,'Caller name %s does not make a good filename.'...
                    , fname);
            end
            this.filename = sprintf('%s-%04d-%02d-%02d__%02d-%02d-%02d-%s',...
                this.subject, floor(clock), fname);
        end

        if isequal(params.logfile, '__auto__')
            params.logfile = regexprep(this.filename, '\.mat()$|(.)$', '$1.log');
        end
        
        %TODO: perhaps see if there's a per-subject config?

        %an total experiment can have many runs. Each run will be saved.
        theRun = ExperimentRun...
            ( 'params', this.params...
            , 'trials', this.trials...
            , 'subject', this.subject...
            , 'description', this.description...
            , 'caller', this.caller...
            );
        e = [];
        try
            [stat, host] = system('hostname');
            if ~isempty(strfind(host, 'pastorianus')) && (~isfield(params, 'input') || isfield(params.input, 'eyes')) && (~isfield(params, 'dummy') || ~params.dummy)
                switchscreen('videoIn', 2, 'videoOut', 1, 'immediate', 1);
                theRun.run();
            else
                theRun.run();
            end
        catch
            theRun.err = lasterror;
            if ~isempty(strfind(host, 'pastorianus')) && (~isfield(params, 'input') || isfield(params.input, 'eyes')) && (~isfield(params, 'dummy') || ~params.dummy)
                switchscreen('videoIn', 1, 'videoOut', 1, 'immediate', 1);
            end
        end
        
        this.runs{end+1} = theRun;

        %now save ourself. Since we overwrite, it is prudent to write
        %to a temp file first.
        if(~isempty(this.filename))
            t = tempname;
            disp( sprintf('writing to temp file %s', t));
            require(openFile(t, 'w'), @(params) dump(this, @(pat, varargin)fprintf(params.fid, [pat '\n'], varargin{:}), 'experiment'));
            finalfile = fullfile(env('datadir'), [this.filename '.txt']);
            movefile(t, finalfile);
            disp( sprintf('saved to %s', finalfile) );
        end

        %if there was an error, report it after saving
        if ~isempty(theRun.err)
            warning('the run stopped with an error: %s', theRun.err.identifier)
            stacktrace(theRun.err);
        end
    end
end