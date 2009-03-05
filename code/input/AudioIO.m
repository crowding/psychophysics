function this = AudioIO(varargin)
    %This is an I/O object that takes input from the audio card using
    %the PsychPortAudio routines.
    %
    %A simple circuit can interface your computer's S/PDIF port with
    %TTL-level inputs and outputs, this can be a very precisely timed
    %method for input and output, with minimal extra hardware.
    %
    %For now, this merely provides floating point audio samples.
    %
    %In the future, this will provide a manager for real-time audio output.
    
    persistent init__;
    this = autoobject(varargin{:});

    useInput = 1; %whether ot use audio input
    useOutput = 0;
    freq = 44100;
    inputChannels = [0 1]; %which channels to use for input, in which order.
    outputChannels = [0 1]; %which channels to use for output, in which order.
    freq = 44100;
    latbias = 30/44100;
    reqlatencyclass = 2;
    deviceid = []; %leave empty to use default, or specify a device.
    channels = 1;
    buffersize = [];
    inputBufferSecs = 5;
    recordInput = 1; %whether to log the recorded input at the end of the trial.
    
%% init
    %init is called at the beginning of the experiment.
    pahandle_ = NaN;
    log_ = @noop;
    function [release, params, next] = init(params)
        if isfield(params, 'log')
            log_ = params.log;
        end
        
        %munge the arguments for PsychPortAudio...
        if useInput && useOutput
            mode = 3;
            channels = [numel(outputChannels) numel(inputChannels)];
            selectChannels = zeros(2, max(channels));
            selectChannels(1,1:numel(outputChannels)) = outputChannels(:)';
            selectChannels(2,1:numel(inputChannels)) = inputChannels(:)';
        elseif useInput
            mode = 2;
            channels = numel(inputChannels);
            selectChannels = inputChannels(:)';
        elseif useOutput
            mode = 1;
            channels = numel(outputChannels);
            selectChannels = outputChannels(:)';
        else
            %what happens then?
            mode = 1;
            channels = 0;
            selectChannels = [];
        end
        
        %open the device
        pahandle_ = PsychPortAudio('Open', deviceid, mode, reqlatencyclass, freq, channels, buffersize, [], selectChannels);
        
        release = @close;
        function close()
            PsychPortAudio('Close', pahandle_);
        end

        next = @setRunMode_;
    end

    function [release, params, next] = setRunMode_(params)
        %since we output audio intermittently, the run mode is 
        previous = PsychPortAudio('RunMode', pahandle_, 1);
    
        release = @undo;
        function undo
            psychPortAudio('RunMode', pahandle_, previous);
        end
        
        next = @setLatency_;
    end

    function [release, params, next] = setLatency_(params)
        previous = PsychPortAudio('LatencyBias', pahandle_, latbias);
        params.soundLatencyBias = PsychPortAudio('LatencyBias', pahandle_);

        release = @close;
        function close()
            PsychPortAudio('LatencyBias', pahandle_, previous);
        end
        
        next = @initRecording_;
    end

    function [release, params] = initRecording_(params)
        if useInput
            %getAudioData needs an initial call for setting up input
            PsychPortAudio('getAudioData', pahandle_, inputBufferSecs, [], []);

            release = @close;
        else
            release = @noop;
        end

        function close
            %does there need to be a recording setting cleanup?
        end
    end
    
%% begin
    %The 'begin' resource is acquired at the beginning of every trial.
    push_ = @noop; %the function to record some data...
    readout_ = @noop; %the function to store data...
    startTime_ = [];
    confirmed = 0;
    recStartTime_ = [];
    sampleRate_ = [];
    lastsampleix_ = -1;
    overflowed_ = 0;
    recordingInput_ = 0;

    function [release, params] = begin(params)
        if useInput && recordInput
            [push_, readout_] = linkedlist(2);
        end
        confirmed = 0;
        startTime_ = PsychPortAudio('Start', pahandle_, 1);
        lastsampleix_ = -1;
        
        release = @stop;
        function stop
            PsychPortAudio('Stop', pahandle_, 0, 0);
            
            if useInput
                data = readout_();
                log_('AUDIO_DATA %s', smallmat2str(data));
            end
            
            if overflowed_
                warning('AudioIO:overflow', 'Audio input buffer overflow detected!');
            end
        end
    end

    %called to say HEY WE'RE REALLY BEGINNING, after n vblanks
    function sync(n,t)
        %we already started though.
    end

%%input
    function state = input(state)
        %once the machine has started,gather info about it...
        if ~confirmed
            status = PsychPortAudio('GetStatus', pahandle_);
            if status.Active
                startTime_ = status.StartTime;
                recStartTime_ = status.CaptureStartTime;
                sampleRate_ = status.SampleRate;
                confirmed = 1;
            end
        end
        
        if useInput
            %input data...
            [data absrecposition overflow cstarttime] = PsychPortAudio('getAudioData', pahandle_);
            if (absrecposition ~= lastsampleix_ + 1) || overflow
                %oops!
                overflowed_ = 1;
            end
            lastsampleix_ = absrecposition + size(data, 2);
            state.audio = data;
            
            %Shouldn't there be some drift correction and calibration here?
            state.audioT = recStartTime_+(absrecposition:absrecposition+size(data,2)-1)/sampleRate_;
            
            if recordInput
                push_([state.audio;state.audioT]);
            end
        end
        if useOutput
            %do something here...
        end
    end
end