function this = GloLoDirectionTrialGenerator(varargin)

    base = GloLoDirectionTrial();
    
    motion_ = base.getMotion();
    dt_ = motion_.getDt();
    
    blocksize = 100;
    interTrialInterval = 1;
    
    %state variable, when to show the next trial...
    nextTrial_ = 0;
    lastEnd_ = 0;

    factors = struct...
        ( 'nTargets', [1 2 3 4 5] ...
        , 'cueOnsetAsynchrony' , [-2*dt_ : dt_/2 : (motion_.getN()+1)*dt_] ...
        , 'minOnset', 0.5 ...
        , 'onsetRate', 1 ...
        , 'minGapAtCue', 2*pi/8 ...
        , 'targetGlobal', [1 -1] ...
        , 'targetLocal', [1 -1] ...
        , 'cueRadius', 0.1 ...
        );
    
    message = @()sprintf('Press down on knob to continue.\n%d blocks remaining.', floor(eval('numel(shuffled_)') / eval('blocksize')));
    
    results = {};

    this = autoobject(varargin{:});
    
    which_ = [];
    shuffled_ = {};
    interstitialShown_ = 0;
    
    function trial = next(params)
        %generate a randomized trial using the given params...
        %remember which one we gave.
        if isempty(shuffled_)
            shuffled_ = factstruct(factors);
        end
        
        if (mod(numel(results), blocksize) == 0) && ~interstitialShown_
            which_ = [];
            trial = interstitial();
            interstitialShown_ = 1;
        else
            which_ = randsample(numel(shuffled_), 1);
            trial = generate(shuffled_(which_), params);
        end
    end

    function has = hasNext()
        if isempty(shuffled_) && isempty(results)
            shuffled_ = factstruct(factors);
        end
        has = ~isempty(shuffled_);
    end

    function t = interstitial();
        t = MessageTrial...
            ( 'message', sprintf('Press space bar or knob to continue.\n%d blocks remaining', ceil(numel(shuffled_)/blocksize))... 
            , 'key', 'Space');
    end

    function times = roundToFrames(times, interval)
        times = round(times ./ interval) * interval;
    end

    function trial = generate(factors, params)
        factors
        trial = deepclone(base);
        %o = Obj(trial);
        mot = trial.getMotion();
        dt = mot.getDt();
        
        onset = roundToFrames(rand(1, factors.nTargets) * dt + factors.minOnset - log(rand()) ./ factors.onsetRate, params.cal.interval);

        mot.setT(onset);
        cueOnset = roundToFrames(factors.cueOnsetAsynchrony + onset(1), params.cal.interval);
        trial.setCueOnset(cueOnset);

        globaldir = [factors.targetGlobal randsample([-1 1], factors.nTargets-1, 1)];
        dphase = mot.getDphase() .* globaldir;
        mot.setDphase(dphase);
        
        r1 = rand();
        r2 = sort(rand(1, factors.nTargets));
        phasesAtCue = mod( r1 * 2*pi ...
                      + factors.minGapAtCue * (0:(factors.nTargets-1)) ...
                      + r2 * (2*pi - factors.nTargets * factors.minGapAtCue)...
                    , 2*pi);
        
        trial.setCueLocation([cos(phasesAtCue(1)) -sin(phasesAtCue(1))] * factors.cueRadius);
        phase = phasesAtCue - (cueOnset - onset(1)) .* dphase / dt
        mot.setPhase(phase);
        
        localdir = [factors.targetLocal randsample([-1 1], factors.nTargets-1, 1)];
        mot.setAngle(180/pi*phase + 90 * localdir);
        trial.setTrialStart(nextTrial_);
    end

    function result(trial, result)
        if ~isempty(which_) && isfield(result, 'success') && result.success && isempty(strfind(trial.version__.function, 'MessageTrial'))
            interstitialShown_ = 0;
            results{end+1} = structunion(result, shuffled_(which_));
            disp(results{end});
            size(results)
            shuffled_(which_) = [];
            which_ = [];
        end
        if isfield(result, 'endTime')
            if (nextTrial_ > 0) && result.startTime > nextTrial_ + 1/50
                fprintf('Missed trial start deadline by %f secs\n', result.startTime - nextTrial_);
            else
                fprintf('no start time given...');
            end
            fprintf('ISI overhead: %f\n', result.isiWaitStartTime - lastEnd_);

            lastEnd_ = result.endTime;
            nextTrial_ = result.endTime + interTrialInterval;
        else
            nextTrial_ = 0;
            lastEnd_ = 0;
        end
    end
end