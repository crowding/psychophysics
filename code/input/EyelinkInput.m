function this = EyelinkInput(varargin)
    %handles eye position input and recording.

    badSampleCount = 0;
    missingSampleCount = 0;
    goodSampleCount = 0;
    
    streamData = 1; %data streaming would be good...
    
    recordFileSamples = 1;
    recordFileEvents = 0;
    recordLinkSamples = 1;
    recordLinkEvents = 0;
    
    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    slowdown_ = [];
    dummy_ = [];
    window_ = [];
    toDegrees_ = @noop;
    
    %default parameters during initialization
    defaults = struct...
        ( 'hideCursor', 0 ... %whether we should hide the mouse cursor
        , 'dummy', 0 ... %whether to simulate eyelink input with the mouse
        );
    
    data = zeros(0,3);
    
    slope = 1 * eye(2); % a 2*2 matrix relating measured position to output position
    offset = [0;0]; %the eye position offset

%% initialization routines

    %the initializer will be called once per experiment and does global
    %setup of everything.
    freq_ = [];
    pahandle_ = [];
    interval_ = [];
    log_ = @noop;
    function [release, params, next] = init(params)
        a = joinResource(defaults, @connect_, @initDefaults_, @doSetup_, getSound(), @openEDF_);
        
        interval_ = params.screenInterval;
        log_ = params.log;
        
        data = zeros(0,3);
        
        [release, params, next] = a(params);
    end

    function [release, details] = connect_(details)
        
        %check the connection before, because:
        %stupidly, Eyelink('Initialize') returns 0 if the eyelink is
        %already initialized IN DUMMY MODE. Bah.
        if Eyelink('isconnected')
            warning('GetEyelink:already_connected', 'Eyelink was left connected');
            Eyelink('ShutDown');
        end
           
        %connect to the eyelink machine.
        if ~isfield(details, 'dummy')
            %auto-choose real or dummy mode
            try
                status = Eyelink('Initialize');
                details.dummy = 0;
            catch
                %There is no rhyme or reason as to why eyelink throws
                %an error and not a status code here
                status = -1;
            end
            if (status < 0)
                warning('GetEyelink:dummyMode', 'Using eyelink in dummy mode');
                status = Eyelink('InitializeDummy');
                details.dummy = 1;
            end
        else
            if details.dummy
                status = Eyelink('InitializeDummy');
            else
                status = Eyelink('Initialize');
            end
            if status < 0
                error('getEyelink:initFailed',...
                    'Initialization status %d', status);
            end
        end

        release = @close;
        
        function close
            if (status >= 0)
                Eyelink('Shutdown');
            end
        end
    end

    %we will need this struct laying around. It doesn't change much.
    persistent el_;
    %initialize eyelink defaults. Requires the 'window' field from getScreen.
    %output fields - 'dummy' if we are in dummy mode
    function [release, details] = initDefaults_(details)
        el_ = EyelinkInitDefaults(details.window);
        details.el = el_;
    
        %hackish, because I don't yet want to tear up EyelinkInitDefaults,
        %but background and foreground color should be specifiable from the
        %experiment outset
        details.el.backgroundcolour = details.backgroundIndex;
        details.el.foregroundcolour = details.foregroundIndex;
        
        [release, details] = deal(@noop, details);
        
        function noop
            %While EyelinkInitDefaults changes the eyelink's screen
            %resolution settings, there is no way to tell what the setings
            %were before, so there is nothing to be done for cleanup.
        end
        
        
    end

    function [release, params] = doSetup_(params)
        %%make sure we have a screen number...
        params = doTrackerSetup(params);
        %set and record as many settings as possible
        if (params.hideCursor)
            HideCursor();
        end
        release = @show;

        function show
            %sonce ther's no way to read the settings off the Eyelink,
            %there's no way to restore state...
            ShowCursor();
        end
    end

    persistent samples_;


%% remote EDF file opening and download
    %open the eyelink data file on the eyelink machine. Upon closing,
    %download the file.
    %input field: dummy: skips a file check in dumy mode
    %output field: edfFilename = the name of the EDF file created
    function [release, details] = openEDF_(details)
        e = env;

        if ~isfield(details, 'edfname')
            %default behavior is to rocord to EDF, if NOT streaming data
            %(if streaming data goes into the log which is easier.)
            if (recordFileSamples || recordFileEvents) && ~streamData
                %pick some kind of unique filename by combining a prefix with
                %a 7-letter encoding of the date and time

                pause(1); % to make it likely that we get a unique filename, hah!
                % oh, why is the eyelink so dumb?
                details.edfname = ['z' clock2filename(clock) '.edf'];
            else
                details.edfname = '';
            end
        end
        
        if ~isfield(details, 'localname') || (~isempty(details.edfname) && isempty(details.localname))
            %choose a place to download the EDF file to
            
            %if we're in an experiment, use those values...
            if all(isfield(details, {'subject', 'caller'}))
                details.localname = fullfile...
                    ( e.eyedir...
                    , sprintf ...
                    ( '%s-%04d-%02d-%02d__%02d-%02d-%02d-%s.edf'...
                    , details.subject, floor(clock), details.caller.function ...
                    ) ...
                    );
            else
                details.localname = fullfile(e.eyedir, details.edfname);
            end
        end

        if ~isempty(details.edfname)
            %the eyelink has no way directly to check that the filename is
            %valid or non-existing... so we must assert that we can't open the
            %file yet.
            tmp = tempname();
            status = Eyelink('ReceiveFile',details.edfname,tmp);
            if (~details.dummy) && (status ~= -1)
                error('Problem generating filename (expected status %d, got %d)',...
                    -1, status);
            end

            %destructive step: open the file
            %FIXME - adjust this according to what data we save...
            Eyelink('command', 'link_sample_data = GAZE');
            status = Eyelink('OpenFile', details.edfname);
            if (status < 0)
                error('getEyelink:fileOpenError', ...
                    'status %d opening eyelink file %s', status, details.edfname);
            end
        else
            %not recording -- don't leave some random previous file open on
            %eyelink
            status = Eyelink('CloseFile');
            if status ~= 0
                error('GetEyelink:couldNotClose', 'status %d closing EDF file', status);
            end
            details.localname = '';
        end
        
        %when we are done with the file, download it
        release = @downloadFile;

        function downloadFile
            %if we were recording to a file, download it
            if ~isempty(details.edfname) && ~isempty(details.localname)
                %try both in any case
                status = Eyelink('CloseFile');
                if Eyelink('IsConnected') ~= details.el.dummyconnected
                    fsize = Eyelink('ReceiveFile', details.edfname, details.localname);

                    if (fsize < 0 || status < 0)
                        error('getEyeink:fileTransferError', ...
                            'File %s empty or not transferred (close status: %d, receive: %d)',...
                            details.edfname, status, fsize);
                    end
                end
            end
        end
    end

%% tracker setup: do calibration

    function details = doTrackerSetup(details)
        details = setupEyelink(details);
        
        if ~details.dummy && flagged(details,'doTrackerSetup')
            message(details, 'Do tracker setup now');
            status = EyelinkDoTrackerSetup(details.el, details.el.ENTER_KEY);
            if status < 0
                error('getEyelink:TrackerSetupFailed', 'Eyelink setup failed.');
            end
        end
        
        %repeat it again since doTrackerSetup turns on filtering, FFS
        details = setupEyelink(details);
    end

%% begin (called each trial)

    clockoffset_ = 0;
    slowdown_ = 1;
    
    push_ = @noop; %the function to record some data...
    readout_ = @noop; %the function to store data...
    
    function [release, details] = begin(details)
        
        freq_ = details.freq;
        pahandle_ = details.pahandle;
        
        badSampleCount = 0;
        missingSampleCount = 0;
        goodSampleCount = 0;

        if isfield(details, 'slowdown')
            slowdown_ = details.slowdown;
        end
        
        toDegrees_ = transformToDegrees(details.cal);
        
        dummy_ = details.dummy;
        window_ = details.window;

        [details.clockoffset, details.clockoffsetMeasured] = getclockoffset(details);
        clockoffset_ = details.clockoffset;
        
        %This field will be set to empty by mainLoop. I will tell it what
        %event fields to remove from the log. Then trigger software will
        %remove them before logging.
        details.notlogged = union(details.notlogged, {'eyeX', 'eyeY', 'eyeT'});
        
        samples_ = 0.9 * sin(linspace(0, 750*2*pi, freq_));
        
        if dummy_
            %do nothing
            release = @noop;
        else
            [push_, readout_] = linkedlist(2);
            
            %status = 
            Eyelink('StartRecording', recordFileSamples, recordFileEvents, recordLinkSamples, recordLinkEvents);
            
            %It retuns -1 but still records! WTF!@!!
            %if status ~= 0
            %    error('EyelinkInput:error', 'status %d starting recording', status);
            %end
            
            %the samples and events are recorded anew each trial.
            release = @doRelease;
        end

        function doRelease
            %clean up our data
            
            %stop recording
            Eyelink('StopRecording');
            %discard the rest...
            while (Eyelink('GetNextDataType'))
            end

            if streamData
                %read out data...
                data = readout_();
                log_('EYE_DATA %s', smallmat2str(data));
                %figure(1);
                %plot(data(3,:) - startTime_, data(1,:), 'b-', data(3,:) - startTime_, data(2,:), 'r-');
                %drawnow;
            end
        end
    end

%% sync
    startTime_ = 0;
    function sync(n, t) %#ok
        %discard data...
        while (Eyelink('GetNextDataType'))
        end
        startTime_ = t + n * interval_;
    end

%% actual input function
    refresh_ = []; 
    next_ = [];
    function k = input(k)
        %Brings in samples from the eyelink and adds them to the structure
        %given as input.
        %Fields added are:
        %   eyeX, eyeY, eyeT (complete traces) and
        %   x, y, t (the latest sample each call).
        %Translates the x and y values to degrees of visual angle.        
        %Coordinates will be NaN if the eye position is not available.

        refresh_ = k.refresh;
        next_ = k.next;
        
        if dummy_
            [x, y, buttons] = GetMouse(window_);
            
            t = GetSecs() / slowdown_;
            if any(buttons) %simulate blinking
                x = NaN;
                y = NaN;
                badSampleCount = badSampleCount + 1;
            else
                goodSampleCount = goodSampleCount + 1;
            end

            [x, y] = toDegrees_(x, y);

            k.x = x;
            k.y = y;
            k.t = t;
        else
            %obtain new samples from the eye.
            if streamData
                
                %calling this pulls in data in high priority mode?
%                Eyelink('NewFloatSampleAvailable');
                data = struct('time',{},'type',{},'flags',{},'px',{},'py',{},'hx',{},'hy',{},'pa',{},'gx',{},'gy',{},'rx',{},'ry',{},'status',{},'input',{},'buttons',{},'htype',{},'hdata',{});
                
                %really need a do-while loop here...
                datatype = Eyelink('GetNextDataType');
                if (datatype)
                    if datatype == 200 %el_.SAMPLE_TYPE
                        %this grows an array, to be sure...
                        data = Eyelink('GetFloatData', datatype);
                    else
                        % an event. As of now we don't record events.
                        % data = Eyelink('GetFloatData', datatype);
                    end
                    datatype = Eyelink('GetNextDataType');
                end                    
                while(datatype)
                    if datatype == 200 %el_.SAMPLE_TYPE
                        %this grows an array, to be sure...
                        d = Eyelink('GetFloatData', datatype);
                        data(end+1) = d; %#ok
                    else
                        % an event. As of now we don't record events.
                        % data = Eyelink('GetFloatData', datatype);
                    end
                    datatype = Eyelink('GetNextDataType');
                end

                if isempty(data)
                    [k.eyeX, k.eyeY, k.eyeT] = deal(zeros(0,1));
                    k.x = NaN;
                    k.y = NaN;
                    k.t = GetSecs() / slowdown_;
                else
                    x = cat(1, data.gx);
                    x = x(:,1)';
                    y = cat(1, data.gy);
                    y = y(:,1)';

                    x(x == -32768) = NaN;
                    y(isnan(x)) = NaN;

                    
                    [x, y] = toDegrees_(x, y);
                    
                    l = [x;y];
                    l = slope*l+offset(:,ones(1,size(l, 2)));

                    k.eyeX = l(1,:);
                    k.eyeY = l(2,:);
                    
                    k.eyeT = ([data.time] - clockoffset_) / 1000 / slowdown_;

                    push_([k.eyeX;k.eyeY;k.eyeT]);

                    %backwards compat -- already written experiments expect
                    %x, y, t to be the latest samples.
                    k.x = k.eyeX(end);
                    k.y = k.eyeY(end);
                    k.t = k.eyeT(end);
                end
            else
                %If you don't want to stream everything into matlab, just 
                %gather the latest sample on every refresh. 
                if Eyelink('NewFloatSampleAvailable') == 0;
                    %no data?
                    x = NaN;
                    y = NaN;
                    t = GetSecs() / slowdown_;
                    missingSampleCount = missingSampleCount + 1;
                else
                    % Probably don't need to do this eyeAvailable check every
                    % frame. Profile this call?
                    eye = Eyelink('EyeAvailable');
                    switch eye
                        case el_.BINOCULAR
                            error('eyeEvents:binocular',...
                                'don''t know which eye to use for events');
                        case el_.LEFT_EYE
                            eyeidx = 1;
                        case el_.RIGHT_EYE
                            eyeidx = 2;
                    end

                    sample = Eyelink('NewestFloatSample');
                    x = sample.gx(eyeidx);
                    y = sample.gy(eyeidx);
                    if x == -32768 %no position -- blinking?
                        badSampleCount = badSampleCount + 1;
                        x = NaN;
                        y = NaN;
                    else
                        goodSampleCount = goodSampleCount + 1;
                    end

                    t = (sample.time - clockoffset_) / 1000 / slowdown_;
                end
                [x, y] = toDegrees_(x, y);

                k.x = x;
                k.y = y;
                k.t = t;
            end
        end
    end

    function [refresh, startTime] = reward(rewardAt, duration)
        %for psychophysics, just produce a beep...
        %generate a buffer...
        PsychPortAudio('Stop', pahandle_);
        PsychPortAudio('FillBuffer', pahandle_, samples_(1:floor(duration/1000*freq_)), 0);
        startTime = PsychPortAudio('Start', pahandle_, 1, 0); %next_ + (rewardAt - refresh_) * interval_);
        refresh = refresh_ + round(startTime - next_)/interval_;
        log_('REWARD %d %d %d %f', rewardAt, duration, refresh, startTime);
    end

    function predictedclock = eventCode(clockAt, code)
        predictedClock = clockAt;
        log_('EVENT_CODE %d %d %d', clockAt, code, clockAt);
    end
end
