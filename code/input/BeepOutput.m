function this = BeepOutput(varargin)
    %This is just beeper stripped out of EyelinkInput. for the concentric
    %trial expeirment running on a machine without eyelink. A 
    %hack. Don't use this (generally).

    persistent init__; %#ok
    this = autoobject(varargin{:});
    
    persistent samples_;
        
%% initialization routines

    %the initializer will be called once per experiment and does global
    %setup of everything.
    freq_ = [];
    pahandle_ = [];
    interval_ = [];
    log_ = @noop;

    function [release, params, next] = init(params)
        interval_ = params.screenInterval;
        log_ = params.log;
        release = @noop;
        next = getSound();
    end

%% begin (called each trial)
    
    function [release, details] = begin(details)
        freq_ = details.freq;
        pahandle_ = details.pahandle;
        samples_ = 0.9 * sin(linspace(0, 750*2*pi, freq_));
        release = @noop;
    end

%% sync
    function sync(n, t) %#ok
    end

%% actual input function
    refresh_ = []; 
    next_ = [];
    function k = input(k)
        refresh_ = k.refresh;
        next_ = k.next;
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
end
