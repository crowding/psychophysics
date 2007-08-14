function initializer = getSound(params)
    
    defaults = struct ...
        ( 'reallyneedlowlatency', 1 ...
        , 'freq', 44100 ...
        , 'latbias', 30/44100 ...
        , 'reqlatencyclass', 2 ...
        , 'deviceid', -1 ...
        , 'buffersize', 64 ...
        , 'channels', 1 ...
        );
    
    if exist('params', 'var')
        defaults = namedargs(defaults, params);
    end

    initializer = @init;
    function [release, params] = init(params)
        params = namedargs(defaults, params);
        
        %TODO there neds to be some calibration for these numbers if I am
        %to care about sound onset times.
        params.pahandle = PsychPortAudio('Open', params.deviceid, [], params.reqlatencyclass, params.freq, params.channels, params.buffersize);
        params.prelat = PsychPortAudio('LatencyBias', params.pahandle, params.latbias);
        params.postlat = PsychPortAudio('LatencyBias', params.pahandle);
        release = @close;
        
        function close() 
            PsychPortAudio('Close', params.pahandle);
        end
    end
end
