function this = SoundOutput()
    %output to the psychportaudio daemon...

    reallyneedlowlatency = 1 ...
    freq = 44100;
    latbias = 30/44100
    reqlatencyclass = 2
    deviceid = -1
    buffersize = 64;
    channels = 1;
    bufferframes_ = 
    
    pahandle_ = [];
    prelat = [];
    postlat = 
    latbias = 30/44100;
    
    if exist('params', 'var')
        defaults = namedargs(defaults, params);
    end

    initializer = @init;
    function [release, params] = init(params)
        pahandle_ = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, channels, buffersize);
        prelat = PsychPortAudio('LatencyBias', pahandle, latbias);
        postlat = PsychPortAudio('LatencyBias', pahandle);
        release = @close;
        
        params.audioFrequency = freq;
        
        function close() 
            PsychPortAudio('Close', pahandle_);
        end
    end

    interval_ = 0;
    function [release, params] = begin(params)
        %called at the beginning of a trial.
        interval_ = params.screenInterval_;
        
        PsychPortAudio('Stop', pahandle);

        buffer = zeros(size
        
        release = @r;
        function r()
            PsychPortAudio('Stop', pahandle);
        end
    end

    function sync(refresh, when)
        %called before the beginning of a trial, to synchronize to a
        %refresh.
        %The buffer needs to be large
        
        data = zeros(round(when + interval_) / 
        PsychPortAudio('FillBuffer'), 
    end

    function k = input(k)
        %"input" is a misnomer -- this gives a report of when audio you
        %generate will hit the speakers, and tells you how many samples to
        %generate. 
    end

    function play(data)
        %add some data to the stream.
        
    end
end