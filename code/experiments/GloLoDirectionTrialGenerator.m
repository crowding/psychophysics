function this = GloLoDirectionTrialGenerator(varargin)

    base = GloLoDirectionTrial();
    
    motion_ = base.getMotion();
    dt_ = motion_.getDt();
    
    blocksize = 100;
    interTrialInterval = 1;
    
    %state variable, when to show the next trial...
    nextTrial_ = 0;

    factors = struct...
        ( 'nTargets', [1 2 3 4 5] ...
        , 'cueOnsetAsynchrony' , [-2*dt_ : dt_/2 : (motion_.getN()+1)*dt_] ...
        , 'minOnset', 0.5 ...
        , 'onsetRate', 1 ...
        , 'minGapAtCue', 2*pi/8 ...
        , 'targetGlobal', [1 -1] ...
        , 'targetLocal', [1 -1] ...
        );
    
    message = @()sprintf('Press down on knob to continue.\n%d blocks remaining.', floor(eval('numel(shuffled_)') / eval('blocksize')));
    
    done = {};
    results = {};

    this = autoobject(varargin{:});
    
    which_ = [];
    shuffled_ = {};
    interstitialShown_ = 0;
    
    function trial = next(params)
        %generate a randomized trial using the given params...
        %remember which one we gave.
        if isempty(shuffled_) && isempty(done)
            shuffled_ = factstruct(factors);
        end
        
        if (mod(numel(done), blocksize) == 0) && ~interstitialShown_
            which_ = [];
            trial = interstitial();
            interstitialShown_ = 1;
        else
            which_ = randsample(numel(shuffled_), 1);
            done_ = {};
            results_ = {};
            trial = generate(shuffled_(which_), params);
        end
    end

    function has = hasNext()
        if isempty(shuffled_) && isempty(done)
            shuffled_ = factstruct(factors);
        end
        has = ~isempty(shuffled_)
    end

    function t = interstitial();
        t = MessageTrial...
            ( 'message', sprintf('Press down on knob to continue.\n%d blocks remaining', ceil(numel(shuffled_)/blocksize))... 
            , 'key', 'Space');
    end

    function times = roundToFrames(times, interval)
        times = round(times ./ interval) * interval;
    end

    function trial = generate(factors, params)
        factors
        trial = deepclone(base);
        o = Obj(trial);
        
        onset = roundToFrames(rand(1, factors.nTargets) * o.motion.dt + factors.minOnset - log(rand()) ./ factors.onsetRate, params.cal.interval);

        o.motion.t = onset;
        o.cueOnset = roundToFrames(factors.cueOnsetAsynchrony + onset(1), params.cal.interval);
        
        r1 = rand();
        r2 = sort(rand(1, factors.nTargets));
        phasesAtCue = mod( r1 * 2*pi ...
                      + factors.minGapAtCue * (0:(factors.nTargets-1)) ...
                      + r2 * (2*pi - factors.nTargets * factors.minGapAtCue)...
                    , 2*pi);
        
        o.fixationPointShiftPhase = phasesAtCue(1);
                
        o.motion.phase = phasesAtCue - (o.cueOnset - onset(1)) .* (o.motion.dphase) / o.motion.dt;
        
        globaldir = [factors.targetGlobal randsample([-1 1], factors.nTargets-1, 1)];
        o.motion.dphase = o.motion.dphase * globaldir;
        
        localdir = [factors.targetLocal randsample([-1 1], factors.nTargets-1, 1)];
        o.motion.angle = 180/pi*o.motion.phase + 90 * localdir;
        o.trialStart = nextTrial_;
    end

    function result(trial, result)
        if ~isempty(which_) && isfield(result, 'success') && result.success && ~isempty(strfind(trial.version__.function, 'MessageTrial'))
            interstitialShown_ = 0;
            done{end+1} = shuffled(which_);
            results{end+1} = results;
            shuffled_(which_) = [];
            which_ = [];
        end
        if isfield('endTime', result)
            nextTrial_ = result.endTime + interTrialInterval;
        end
    end
end