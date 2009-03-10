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
window = [];
handles = [];

params = namedargs...
        (localExperimentParams()...
        , struct ...
            ( 'logfile', '__auto__'...
            , 'hideCursor', 1 ...
            , 'continuing', 0 ...
            ) ...
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

    function show()
        %build an Experiment window, or show it.
        if isempty(window) || ~ishandle(window)
            %set it up so that the window handle clears on closing...
            window = figure();
            set(window, 'DeleteFcn', @closing);
            set(window, 'Toolbar', 'none', 'Name', caller.function, 'NumberTitle', 'off', 'MenuBar', 'none');
            
            %create in it some panels.
            handles.prop_panel = uipanel('Parent', window, 'Position', [0 0 0.5 0.9], 'Title', 'Properties');
            handles.button_panel = uipanel('Parent', window, 'Position', [0 0.9 0.5 0.1], 'Title', 'Run/Stop');
            handles.trial_panel = uipanel('Parent', window, 'Position', [0.5 0.5 0.5 0.5], 'Title', 'Last trial');
            handles.trial_axes = axes('Parent', handles.trial_panel);
            handles.experiment_panel = uipanel('Parent', window, 'Position', [0.5 0 0.5 0.5], 'Title', 'Experiment');
            handles.experiment_axes = axes('Parent', handles.experiment_panel); 
            
            %create the start and stop buttons.
            handles.start_button = uicontrol(handles.button_panel, 'Style', 'pushbutton', 'Units', 'Normalized', 'String', 'Start', 'Position', [0 0 0.5 1], 'BackgroundColor', [0.5 1 0] );
            handles.stop_button = uicontrol(handles.button_panel, 'Style', 'pushbutton', 'Units', 'Normalized', 'String', 'Stopped', 'Position', [0.5 0 0.5 1], 'BackgroundColor', [0.8 0.8 0.8], 'Enable', 'off');

            set(handles.start_button, 'Callback', @start_);
            
            %create the property explorer.
        else
            figure(window);
        end
        
        function closing(hObject, edata, h) %#ok
            window = [];
            handles = [];
        end
    end

    function start_(hObject, edata, h) %#ok
        require(@showStarting_, this.run);
    end

    function [release, params] = showSaving_(params)
        if ~isempty(handles)
            prevstart = getandset_(handles.start_button, 'BackgroundColor', [0.8 0.8 0.8], 'Enable', 'off', 'String', 'Saving...');
            prevstop = getandset_(handles.stop_button, 'BackgroundColor', [0.8 0.8 0.8], 'Enable', 'off', 'String', 'Saving...');
        end
        
        release = @r;
        function r()
            if ~isempty(handles)
                set(handles.start_button, prevstart{:});            
                set(handles.stop_button, prevstop{:});            
            end
        end
    end


    function [release, params] = showStarting_(params)
        if ~isempty(handles)
            prev = getandset_(handles.start_button, 'Enable', 'off', 'String', 'Starting...');
        end
        
        release = @r;
        function r()
            if ~isempty(handles)
                set(handles.start_button, prev{:});            
            end
        end
    end

    function prev = getandset_(obj, varargin)
        %set a list of properties, but return the previous values (as a cell list of arguments) first.
        args = reshape(varargin, 2, []);
        for i = 1:size(args, 2)
            args{2,i} = get(obj, args{1,i});
        end
        prev = reshape(args, 1, []);
        set(obj, varargin{:});
    end

    function run(varargin)
        if isempty(subject)
            subject = input('Enter subject initials: ', 's');
        end
        
        if ~isvarname(subject)
            error('Experiment:invalidInput','Please use only letters and numbers in subject identifiers.');
        end

        params = namedargs(params, varargin{:});
        if ~isempty(handles)
            params.uihandles = handles;
        end

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
        params.subject = this.subject;
        theRun = ExperimentRun...
            ( 'params', params...
            , 'trials', trials...
            , 'description', description...
            , 'caller', caller...
            );
        try %GAH. this should be abstracted and put in some per host config.
            [stat, host] = system('hostname');
            if ~isempty(strfind(host, 'pastorianus'))
                switchscreen('videoIn', 1, 'videoOut', 1, 'immediate', 1);
                require(@showRunning, theRun.run);
            else
                require(@showRunning, theRun.run);
            end
        catch
            theRun.setErr(lasterror);
            if ~isempty(strfind(host, 'pastorianus'))
                switchscreen('videoIn', 1, 'videoOut', 1, 'immediate', 1);
            end
        end

        function stop(hObject, edata, h) %#ok
            if ~isempty(handles)
                set(handles.stop_button, 'BackgroundColor', [1 0.1 0.1], 'Enable', 'off', 'String', 'Stopping');
            end
            theRun.stop();
        end

        function [release, params] = showRunning(params)
            if ~isempty(handles)
                prevstart = getandset_(handles.start_button, 'BackgroundColor', [0.8 0.8 0.8], 'Enable', 'off', 'String', 'Running');
                prevstop = getandset_(handles.stop_button, 'BackgroundColor', [1 0.1 0.1], 'Enable', 'on', 'String', 'Stop', 'Callback', @stop);
            end

            release = @r;
            function r()
                if ~isempty(handles)
                    set(handles.start_button, prevstart{:});
                    set(handles.stop_button, prevstop{:});
                end
            end
        end
        
        require(@showSaving_, @save);
        function save(p) %#ok
            runs{end+1} = theRun; %#ok

            %now save ourself. Since we overwrite, it is prudent to write
            %to a temp file first.

            if(~isempty(filename))
                t = tempname;
                disp( sprintf('writing to temp file %s', t));
                require(openFile(t, 'w'), @(params) dump(this, @(pat, varargin)fprintf(params.fid, [pat '\n'], varargin{:}), 'experiment'));
                finalfile = fullfile(env('datadir'), [this.filename '.txt']);
                movefile(t, finalfile);
                disp( sprintf('saved to %s', finalfile) );
            end

            %if there was an error, report it after saving.
            if ~isempty(theRun.getErr())
                err = theRun.getErr();
                warning(err.identifier, 'the run stopped with an error: %s', err.identifier);
                stacktrace(err);
            end
        end
    end

    function t = getTrials
        t = trials;
    end
end