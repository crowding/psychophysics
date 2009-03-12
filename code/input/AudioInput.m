function this = AudioInput(varargin)
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

    freq = 48000;
    channels = [0 1]; %which channels to use for input, in which order.
    freq = 11025;
    latbias = 30/44100;
    reqlatencyclass = 4;
    deviceid = []; %leave empty to use default, or specify a device.
    buffersize = [];
    bufferSecs = 5;
    record = 1; %whether to log the recorded input at the end of the trial.

%% init
    %init is called at the beginning of the experiment.
    pahandle_ = NaN;
    log_ = @noop;
    function [release, params, next] = init(params)
        if isfield(params, 'log')
            log_ = params.log;
        end
        
        %munge the arguments for PsychPortAudio...
        mode = 2;
        nChannels = numel(channels);
        selectChannels = channels(:)';

        %open the device
        pahandle_ = PsychPortAudio('Open', deviceid, mode, reqlatencyclass, freq, nChannels, buffersize, [], selectChannels);
        
        release = @close;
        function close()
            PsychPortAudio('Close', pahandle_);
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
        %allocate input buffers
        %getAudioData needs an initial call for setting up input
        PsychPortAudio('getAudioData', pahandle_, bufferSecs, [], []);

        release = @close;
        function close
            %does there need to be a recording setting cleanup?
        end
    end
    
%% begin
    %The 'begin' resource is acquired at the beginning of every trial.

    confirmed_ = 0;
    
    %hidden state for input
    push_ = @noop; %the function to record some data...
    readout_ = @noop; %the function to store data...
    recStartTime_ = [];
    sampleRate_ = [];
    lastsampleix_ = -1;
    overflowed_ = 0;
    
    function [release, params] = begin(params)
            params.notlogged = union(params.notlogged, {'audio', 'audioT'});
        if record
            [push_, readout_] = linkedlist(2);
        end
        confirmed_ = 0;
        startTime_ = PsychPortAudio('Start', pahandle_, 1);
            
        recStartTime_ = startTime_;
        lastsampleix_ = -1;
        overflowed_ = 0;
        
        release = @stop;
        function stop
            PsychPortAudio('Stop', pahandle_, 0, 0);
            
            if record
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
        %do-nothing. we already started up in begin().
    end

%%input
    function state = input(state)
        %once the machine has started,gather info about it...
        if ~confirmed_
            status = PsychPortAudio('GetStatus', pahandle_);
            if status.Active
                recStartTime_ = status.CaptureStartTime;
                sampleRate_ = status.SampleRate;
                confirmed_ = 1;
            end
        end
        %input data...
        [data absrecposition overflow ctstarttime] = PsychPortAudio('getAudioData', pahandle_);
        if (~isempty(data) && (absrecposition ~= lastsampleix_ + 1)) || overflow
            %oops!
            overflowed_ = 1;
        end
        lastsampleix_ = lastsampleix_ + size(data, 2);
        state.audio = data;

        %Shouldn't there be some drift correction and calibration here?
        state.audioT = recStartTime_+(absrecposition:absrecposition+size(data,2)-1)/sampleRate_;

        if record
            push_([state.audio;state.audioT]);
        end
    end
end