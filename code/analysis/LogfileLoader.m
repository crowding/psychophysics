function this = LogfileLoader(varargin)
    
    %Reads experiment log files and bakes them into structs.
    
    %default handlers
    messageHandlers = ...
        { 'BEGIN EXPERIMENT_RUN', @beginExperiment ...
        ; 'BEGIN TRIAL', @beginTrial ...
        ; 'TRIGGER', @handleTrigger ...
        ; 'MOUSE_MOVE', @handleTrigger ...
        ; 'FRAME_SKIP', @handleFrameSkip ...
        ; 'EYE_DATA', @handleEyeData
        };
    
    beginTrialCallback = @(x)x;
    endTrialCallback = @(x)x;

    %set this to true and we will run constructors to reconstitute objects.
    %Otherwise we just make the structs.
    runConstructors = 0;
    
    data = {};

    persistent init__; %#ok;
    this = autoobject(varargin{:});
    %----------------------------------------------------------------------
    %By default, collect experiment runs, trials, and sample data    
    line_ = '';
    trial_ = [];
    experiment_ = [];
    
    %for line breaks
    line_ = '';
    lineLine_ = 0;
    %for weird acausal line breaks
    storedEnd_ = '';
    storedEndLine_ = 0;
    storedBeginning_ = '';
    storedBeginningLine_ = 0;

    %this will be prepended to all evaluated assignments
    context_ = '';
    
    %a freakin' kludge this is... We add the ability to have a callback ath
    %the beginning and end of trials...
    
    function reset()
        line_ = '';
        lineLine_ = 0;
        storedEnd_ = '';
        storedEndLine_ = 0;
        storedBeginning_ = '';
        storedBeginningLine_ = 0;
        trial_ = [];
        experiment_ = [];
        context_ = '';
        data = {};
    end
    
    function dataout = fscan(filename)
        reset();
        scanfile(filename);
        dataout = data;
    end

    function scanfile(filename)
        fid = fopen(filename);
        lineNo = 1;
        while (1)
            line = fgetl(fid);
            if line == -1
                break;
            end
            handleLine(line, NaN, lineNo);
            lineNo = lineNo + 1;
        end
        
        fclose(fid);
    end

    function fromreadline(params)
        %expects a "readline" field in the params, and uses that.
        rl = params.readline;
        lineNo = 1;
        while (1)
            line = rl();
            if line == -1
                break;
            end
            handleLine(line, NaN, lineNo);
            lineNo = lineNo + 1;
        end
    end

    function handleLine(line, time, lineNo)
        %time is ignored since each event carries TEH REAL TIMESTAMP from
        %the eyelink data, ar close to when it was measured.
        
        %Now, this got complicated because the sometimes the eyelink got
        %messages out of order. Crap. I will replace my ethernet switch
        %with a direct connection.
        if isempty(line)
            return;
        end
        
        %there are some heuristic markers for the beginning of a message:
        %an all-caps word or '(something with no spaces) = '
        if regexp(line, '^(?:[^\s]* = |[A-Z!][A-Z0-9_]*(?:\s|$))')
            %Assignments should be on new lines...
            if ~isempty(line_)
                if ~isempty(storedEnd_) && abs(storedEndLine_ - lineLine_) < 200
                    %hmm, maybe we should mix in a stored end
                    line_ = [line_ storedEnd_];
                    storedEnd_ = '';
                    warning( 'LogfileLoader:outOfOrder'...
                           , 'guessing line %d continues at %d'...
                           , lineLine_, storedEndLine_);
                    if ~handleCompleteLine_(line_, lineNo);
                        warning( 'LogfileLoader:mixedUp'...
                               , 'giving up on chunk at line %d'...
                               , lineLine_);
                    end
                    line_ = '';
                else
                    warning( 'LogfileLoader:incompleteLine'...
                           , 'Message beginning line %d not terminated At %d'...
                           , lineLine_, lineNo);
                    if ~isempty(storedBeginning_)
                        warning( 'LogfileLoader:mixedUp'...
                                   , 'giving up on chunk at line %d'...
                                   , storedBeginningLine_);
                    end
                    storedBeginning_ = line_;
                    storedBeginningLine_ = lineLine_;
                    line_ = '';
                end
            end
        end
        
        if isempty(line_)
            lineLine_ = lineNo;
        end
        
        if line(end) == '\'
            line_ = [line_ line(1:end-1)];
        else
            %we got a message end
            line_ = [line_ line];
            
            %we have a line ending, check if it is a whole line.
            if ~handleCompleteLine_(line_, lineLine_)
                %this ended message doesn't seem to do anything. Next shot,
                %try for a stored beginning.
                if ~isempty(storedBeginning_) && abs(storedBeginningLine_ - lineLine_) < 200
                    warning( 'LogfileLoader:outOfOrder'...
                        , 'guessing line %d continues at %d'...
                        , storedBeginningLine_, lineLine_);
                    line_ = [storedBeginning_ line_];
                    storedBeginning_ = '';
                    lineLine_ = storedBeginningLine_;
                    if ~handleCompleteLine_(line_, lineLine_)
                        warning( 'LogfileLoader:mixedUp'...
                               , 'giving up on chunk at line %d'...
                               , lineLine_);
                    end
                else
                    if ~isempty(storedEnd_)
                        warning( 'LogfileLoader:mixedUp'...
                               , 'giving up on chunk at line %d'...
                               , storedEndLine_);
                    end
                    warning('Bad message at %d (no beginning of multi-line message?)', lineLine_);
                    storedEnd_ = line_;
                    storedEndLine_ = lineLine_;
                end
            end
               
            line_ = '';
        end
    end
    
        function t = handleCompleteLine_(line, lineNo)
            t = 0;
            try
                if regexp(line, '^[A-Z!][A-Z0-9_]*(?:\s|$)')
                    %all caps, no punch, it's a message handler
                    for h = messageHandlers'
                        %switch on the first characters
                        if strncmp(line, h{1}, length(h{1}))
                            h{2}(line); %call the handler
                            break;
                        end
                    end
                    t = 1;
                elseif regexp(line, '^[^\s]* = ')
                    %an assignment, it is a bit of data
                    if strfind(line, ' = ')
                        %if it's a constructor call...
                        if regexp(line, '^(.+)\s*=\s*[\w/]+\(\s*\1\s*\)')
                            if runConstructors
                                line = regexprep(line, '^(.+)\s*=\s*(\w+)\(\s*\1\s*\)'...
                                    , '${context_}$1 = $2(${context_}$1)');
                                eval(line);
                            end
                        else
                            eval([context_ line]);
                        end
                    end
                    t = 1;
                else
                    t = 0;
                end
            catch
                e = lasterror;
                e.message = sprintf('Error at line %d: %s', lineNo, e.message);
                warning('logFileLoader:evalError', e.message);
            end
        end

    slope_ = [];
    offset_ = [];
    function beginExperiment(line)
        fprintf(2, '%s\n',line);
        experiment_ = struct('trials', {{}});
        oldContext = context_;
        context_ = 'experiment_.';
        slope_ = [];
        offset_ = [];
        function endExperiment_(line)
            context_ = oldContext;
            endExperiment(line)
        end
        addMessageHandler('END', @endExperiment_);
    end

    function endExperiment(line)
        data = cat(1, data, {experiment_});
        removeMessageHandler('END');
    end

    function beginTrial(message)
        %FIXME should make samples into structs
        %note, see how the 
        trial_ = struct ...
            ( 'triggers', {{}} ...
            , 'frame_skips', {{}} ...
            );
        
        %assignments go to the trial struct now
        oldContext = context_;
        context_ = 'trial_.';
        function endTrial_(message)
            context_ = oldContext;
            endTrial(message);
        end
        trial_ = beginTrialCallback(trial_);
        
        addMessageHandler('END', @endTrial_);
    end

    function endTrial(message)
        %FIXME - the log/data file should specify these custom fields somehow, but I
        %don't see where...
        
        %build a struct of arrays (reputed to be faster and less memory
        %than an array of structs, even though the latter makes loads more
        %sense)
        trial_.triggers = structcat(trial_.triggers);
        trial_.frame_skips = structcat(trial_.frame_skips);
        trial_ = endTrialCallback(trial_);
        
        %if a calibration is entered, remember it.
        if isfield(trial_, 'result') && isfield(trial_.result, 'success') && trial_.result.success ~= 0 && isfield(trial_.result, 'slope') && isfield(trial_.result, 'offset')
            slope_ = trial_.result.slope;
            offset_ = trial_.result.offset;
        end
        
        if isfield(trial_, 'eyeData')
            %apply eye calibration ONLY FOR LABJACK DATA!!!!! (whoops) (since
            %the raw data is stored)
            if strcmp(experiment_.beforeRun.params.input.eyes.version__.function, 'LabJackInput')
                tocalibrate = trial_.eyeData(1:2,:);
                %ALSO TODO: watch for calibration trials and use the to update
                %calibration slopes....
                if isempty(slope_)
                    slope_ = experiment_.beforeRun.params.input.eyes.slope;
                    offset_ = experiment_.beforeRun.params.input.eyes.offset;
                end

                calibrated = slope_ * tocalibrate + offset_(:,ones(1, size(tocalibrate,2)));
                trial_.eyeData(1:2,:) = calibrated;
            end
        end
        
        experiment_.trials = cat(1, experiment_.trials, trial_);
        
        fprintf(2, '%d\n',numel(experiment_.trials));
        
        removeMessageHandler('END');
    end


    function handleTrigger(message)
        %there are a few different formats we have to deal with.

        %The old format begins with a number after the trigger message.
        %this reads the old format
        triggerData = textscan(message, '%s %n, %n, %n, %n, %s', 'BufSize', 2^24);
        %check if it worked, else try the new format...
        if ~isempty(triggerData{2})
            sargs = {'message', 'pcx', 'pcy', 'pct', 'pcnext', 'name'; data{:}};
            trial_.triggers{end+1} = struct(sargs{:});
        else
            triggerData = textscan(message, '%s %s %[^\n]', 'BufSize', 2^24);
            s = str2struct(triggerData{3}{1});
            s.name = triggerData{2}{1};
            s.message = triggerData{1}{1};
            trial_.triggers{end+1} = s;
        end
    end

    function handleFrameSkip(message)
        triggerData = textscan(message, '%s %n %n %n %n', 'BufSize', 2^24);
        sargs = {'message', 'skips', 'prevVBL', 'VBL', 'refresh'; triggerData{:}};
        trial_.frame_skips{end+1} = struct(sargs{:});
    end

    function handleEyeData(message)
        eyeData = textscan(message, '%s %[^\n]', 'BufSize', 2^24);
        eyeData = eval(eyeData{2}{1}); %just a bunch of numbers....
        
        %they are stored raw, so apply calibration\
        
        trial_.eyeData = eyeData;
    end

    function addMessageHandler(prefix, handler)
        messageHandlers = cat(1, {prefix, handler}, messageHandlers());
    end

    function removeMessageHandler(prefix)
        for i = 1:size(messageHandlers, 1)
            if strcmp(messageHandlers(i,1), prefix)
                messageHandlers(i,:) = [];
                break;
            end
        end
    end

    function skipTrial(time, message)
        tmpMHandlers = messageHandlers;
        
        messageHandlers = { 'END ', @restore };
        
        function restore(time, message)
            handlers = tmpHandlers;
            messageHandlers = tmpMHandlers;
            
            %remove the 'END TRIAL' handler
            removeMessageHandler('END');
            %we then do not call 'endTrial,' so the trial is discarded
        end
    end

end