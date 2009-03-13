function this = AudioOutput(varargin)
    %This is an object that provides output to the audio card using
    %the PsychPortAudio routines.
    %
    %A simple circuit can interface your computer's S/PDIF port with
    %TTL-level inputs and outputs, this can be a very precisely timed
    %method for input and output, with minimal extra hardware.
    
    freq = 44100;
    channels = [0 1]; %which channels to use for output, in which order.
    latbias = 30/44100;
    reqlatencyclass = 4;
    deviceid = []; %leave empty to use default, or specify a device.
    buffersize = [];
    bufferSecs = 5; %this actually probably doesn't matter for online audio computation, as long as it's large enough to get you to the next frame.
    record = 0; %whether to record the generated output for posterity.
    outputFunction = @dummy;
    framesAhead = 1; %normally we compute through the next refresh. Up this if you want audio to be mroe robust to frame skips.

    persistent init__;
    this = autoobject(varargin{:});
    
%% init
    %init is called at the beginning of the experiment.
    pahandle_ = NaN;
    log_ = @noop;
    interval_ = 0;
    function [release, params, next] = init(params)
        if isfield(params, 'log')
            log_ = params.log;
        end
        
        %munge the arguments for PsychPortAudio...
        mode = 1;
        nChannels = numel(channels);
        selectChannels = channels(:)';
        
        %open the device
        pahandle_ = PsychPortAudio('Open', deviceid, mode, reqlatencyclass, freq, nChannels, buffersize, [], selectChannels);
        
        release = @close;
        function close()
            PsychPortAudio('Close', pahandle_);
        end

        next = @setRunMode_;
    end

    function [release, params, next] = setRunMode_(params)
        status = PsychPortAudio('GetStatus', pahandle_);
        sampleRate_ = status.SampleRate;
        interval_ = params.cal.interval;

        %since we might output audio intermittently, the run mode is set to
        %allow this.
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
        
        next = @initOutput_;
    end

    function [release, params] = initOutput_(params)
        %allocate output buffers
        outputBufferSize_ = 1024 * ceil(bufferSecs * sampleRate_ / 1024);
        underflow = PsychPortAudio('FillBuffer', pahandle_, repmat(dummy(0, outputBufferSize_, sampleRate_, 0),numel(channels),1) );
        PsychPortAudio('SetLoop', pahandle_); %a circular buffer; loop everything
        lastIndex_ = 0; %the last index that was submitted for data...
        
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

    startTime_ = [];
    sampleRate_ = [];
    lastsampleix_ = -1;
    outputBufferSize_ = [];
    hardwareBufferSize_ = 0;
    underflowed_ = 0;
    startTime_ = [];
    
    function [release, params] = begin(params)
        if record
            [push_, readout_] = linkedlist(2);
        end
        confirmed_ = 0;
        startTime_ = PsychPortAudio('Start', pahandle_, 0);
        
        lastsampleix_ = -1;
        underflowed_ = 0;
        
        release = @stop;
        function stop
            PsychPortAudio('Stop', pahandle_, 0, 0);
            
            if record
                data = readout_();
                log_('AUDIO_OUT %s', smallmat2str(data));
            end
            
            if underflowed_
                warning('AudioOutput:overflow', 'Audio output buffer underflow detected!');
            end
        end
    end

    %called to say HEY WE'RE REALLY BEGINNING, after n vblanks
    function sync(n,t)
        %do-nothing. we already started up in begin().
    end

%% input
    function state = input(state)
        %once the machine has started,gather info about it...
        status = PsychPortAudio('GetStatus', pahandle_);
        if ~confirmed_
            if status.Active
                startTime_ = status.StartTime;
                sampleRate_ = status.SampleRate;
                hardwareBufferSize_ = status.BufferSize;
                confirmed_ = 1;
            else
                return;
            end
        end
        %we need to make sure data is queued up through this upcoming
        %refresh and the next.
        
        %firstSample = hardwareBufferSize_*floor(max(lastsampleix_ + 1, status.PositionSecs * sampleRate_)/hardwareBufferSize_);
        firstSample = lastsampleix_+1;
        onset = firstSample/sampleRate_ + startTime_;
        lastSample = hardwareBufferSize_*ceil((state.next + interval_*framesAhead - startTime_) * sampleRate_/hardwareBufferSize_);
%        lastSample = (state.next + interval_*framesAhead - startTime_) * sampleRate_;
        nSamples = max(lastSample - firstSample, 0);
        
        %Use this information to generate audio (depending on the
        %experiment)
        data = outputFunction(firstSample, nSamples, sampleRate_, onset);
        
        %fill the buffer
        bufferIndex = mod(firstSample, outputBufferSize_);
        [firstSample / status.PositionSecs firstSample / (state.next - startTime_)];
        %PsychPortAudio('FillBuffer', pahandle_, data, 1);
        if (bufferIndex + nSamples >= outputBufferSize_)
            if bufferIndex+nSamples == outputBufferSize_
                PsychPortAudio('RefillBuffer', pahandle_, 0, data, bufferIndex);
            else
                endn = outputBufferSize_ - bufferIndex;
                PsychPortAudio('RefillBuffer', pahandle_, 0, data(:,1:endn), bufferIndex);
                PsychPortAudio('RefillBuffer', pahandle_, 0, data(:,endn+1:end), 0);
            end
        else
            PsychPortAudio('RefillBuffer', pahandle_, 0, data, bufferIndex);
        end
        lastsampleix_ = lastsampleix_ + nSamples;
    end

%%
    %prototype function takes five arguments -- first sample in chunk index, chunk length, sample rate,
    %estimated time of first sample.
    function out = dummy(from,howmany,rate,onset)
        %dummy tone
        out = 0.9 * sin((from:from+howmany-1) * 2*pi*440/rate);
    end
end