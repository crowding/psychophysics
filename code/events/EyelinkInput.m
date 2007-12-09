function this = EyelinkInput(varargin)
    %handles eye position input and recording.

    badSampleCount = 0;
    missingSampleCount = 0;
    goodSampleCount = 0;
    
    doInitialTrackerSetup = 1;
    streamData = 0; %data streaming would be good but is too slow...
    
    persistent init__;
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

%% initialization routines

    %the initializer will be called once per experiment and does global
    %setup of everything.
    function [release, params] = init(params)
        if doInitialTrackerSetup
            a = joinResource(@connect_, @initDefaults_, @doSetup_, @openEDF_);
        else
            a = joinResource(@connect_, @initDefaults_, @openEDF_);
        end
        
        [release, params] = a(namedargs(defaults, params));
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


%% remote EDF file opening and download
    %open the eyelink data file on the eyelink machine. Upon closing,
    %download the file.
    %input field: dummy: skips a file check in dumy mode
    %output field: edfFilename = the name of the EDF file created
    function [release, details] = openEDF_(details)
        e = env;

        if ~isfield(details, 'edfname')
            %pick some kind of unique filename by combining a prefix with
            %a 7-letter encoding of the date and time

            pause(1); % to make it likely that we get a unique filename, hah!
                      % oh, why is the eyelink so dumb?q
            details.edfname = ['z' clock2filename(clock) '.edf'];
        end
        
        if ~isfield(details, 'localname') || (~isempty(details.edfname) && isempty(details.localname))
            %make a note of where we will find the file locally
            
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
            %FIXME - what data can I get out of here?
            Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
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
    %we need to keep these to interpret the data coming down the pipe
    eventfields_ = {};
    samplefields_ = {};

    function details = doTrackerSetup(details)
        details = setupEyelink(details);
        
        if details.dummy
            @noop;
        else
            message(details, 'Do tracker setup now');
            status = EyelinkDoTrackerSetup(details.el, details.el.ENTER_KEY);
            if status < 0
                error('getEyelink:TrackerSetupFailed', 'Eyelink setup failed.');
            end
        end
        
        %repeat it again since doTrackerSetup turns on filtering, FFS
        details = setupEyelink(details);
        
        %remember the order of the data coming down the pipe
        samplefields_ = splitstr(',', details.eyelinkSettings.link_sample_data);
        eventfields_ = splitstr(',', details.eyelinkSettings.link_event_data);
    end

%% begin (called each trial)

    clockoffset_ = 0;
    slowdown_ = 1;
    function [release, details] = begin(details)
        badSampleCount = 0;
        missingSampleCount = 0;
        goodSampleCount = 0;

        if isfield(details, 'slowdown')
            slowdown_ = details.slowdown;
        end
        
        toDegrees_ = transformToDegrees(details.cal);
        
        dummy_ = details.dummy;
        window_ = details.window;

        %[details.clockoffset, details.clockoffsetMeasured] = getclockoffset(details);
        %clockoffset_ = details.clockoffset
        
        if dummy_
            %do nothing
            release = @noop;
        else
            status = Eyelink('StartRecording', 1, 1, 1, 1);

            %It retuns -1 but still records! WTF!@!!
            %if status ~= 0
            %    error('EyelinkInput:error', 'status %d starting recording', status);
            %end
            
            %the samples and events are recorded anew each trial.
            samples_ = {};
            nsamples_ = 0;
            events_ = {};
            nevents_ = 0;
            
            release = @doRelease;
        end

        function doRelease
            %clean up our data
            if streamdata
                s = samples_;
                ns = nsamples_;
                e = events_;
                ne = nevents_;

                samples_ = {};
                nsamples_ = 0;
                events_ = {};
                nevents_ = 0;
            end
            
            %stop recording
            Eyelink('StopRecording');
            
            if streamdata
                %concatenate the trace...
                if ns > 0
                    ss = s{1};
                    ss(ns) = ss;
                    s = s{2};
                    for i = 2:ns
                        ss(i) = s{1};
                        s = s{2};
                    end

                    %concatenate further
                    for i = fieldnames(ss)'
                        ss(1).(i{:}) = cat(1, ss.(i{:}));
                    end

                    ss = ss(1);
                end
            end
            
            %TODO log to disk...
        end
    end

samples_ = {};
nsamples_ = 0;
events_ = {};
nevents_ = 0;

%% sync
    function sync(n)
        %%nothing needed
    end

%% actual input function
    function k = input(k)
        %Takes a sample from the eye, or mouse if the eyelink is not
        %connected. Returns x and y == NaN if the sample has invalid
        %coordinates. Otherwise returns a value in degrees.

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
        else
            %obtain a new sample from the eye.
            if streamdata
                %unfortunately this is half baked and hte library's not
                %fast enough to keep up...
                datatype = Eyelink('GetNextDataType');
                while(datatype)
                    if datatype == el_.SAMPLE_TYPE
                        data = Eyelink('GetFloatData', datatype);
                        samples_ = {data samples_};
                        nsamples_ = nsamples_ + 1;
                    else
                        % an event
                        %data = Eyelink('GetFloatData', datatype);
                        %events = {data events};
                        %nevents_ = nevents_ + 1;
                    end
                    datatype = Eyelink('GetNextDataType');
                end
            end
            
            if Eyelink('NewFloatSampleAvailable') == 0;
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
        end
        [x, y] = toDegrees_(x, y);
        
        k.x = x;
        k.y = y;
        k.t = t;
    end

end