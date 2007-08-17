function this = CircleInterpolationTrialGenerator(varargin)
    %Generate trials that explore interpolation (response using the mouse.)

    %the base gives the basic parameters of the trial. It will be cloned
    %for each trial.
    base = CircleInterpolationTrial();
    
    nTargets = 5; %number of targets to use. in generating trials.
    
    minGap = 2*pi/8; %this many radians (on the circle) between all targets at the
                     %time of the flash.

    numInBlock = 50; %number of trials in a block.
    
    %the "onset asynchrony" is the time between the center of the target's
    %first appearance and the onset of the bar.
    onsetAsynchronies = 0;
    
    %after acquiring ifxation, stimulus onset happens here
    baseOnset = 0.5;
    
    %Comparison bars are shown this long after the last appearance of the
    %target
    comparisonBarDelay = 0.5;
    
    %the "normal displacement" is the linear offset of the flash ahead of
    %the target's linearly interpolated position.
    %(positive values are in the direction of translation.)
    interpolatedDisplacements = 0;

    %These arrays maintain the list of trials yet to be done.
    shuffleOnsetAsynchrony = []; %time of flash from centroid of first target appearance
    
    %now, the "flash displacement" is the linear offset of the flash from
    %the (interpolated) location of the target at stimulus onset.
    shuffleFlashDisplacement = []; %Absolute linear displacement of flash
    shuffleConsistent = []; %Whether motion is consistent in this trial.
    shuffleDx = []; %dx of the target.

    shuffle_();
    
    this = autoobject(varargin{:});
    
    %------------------ methods...

    function n = setOnsetAsynchronies(n)
        onsetAsynchronies = n;
        shuffle_();
    end

    function n = setInterpolatedDisplacements(n)
        interpolatedDisplacements = n;
        shuffle_();
    end

    function d = setBase(d)
        base = d;
        shuffle_();
    end
        
    function shuffle_()
        dx = base.getDx();
        dt = base.getDt();
        dx = dx(1);
        dt = dt(1);
        [soa, snd, sc, sdx] = ndgrid(onsetAsynchronies, interpolatedDisplacements, [0 1], [dx -dx]);
        shuffleOnsetAsynchrony = soa(:);
        shuffleDx = sdx(:);
        shuffleConsistent = sc(:);
    
        %the "flash displacement" is an absolute distance from the onset.
        shuffleFlashDisplacement = snd(:) + sdx(:) ./ dt .* soa(:);

        %{
        figure(1); clf;
        plot(shuffleFlashDisplacement, shuffleOnsetAsynchrony, 'ko');
        hold on;
        plot((0:(nStations-1))*dx, (0:(nStations-1))*dt, 'k.');
        hold off;
        %}
    end

    blockCounter_ = 0;
    function startBlock()
        blockCounter_ = numInBlock;
    end

    function has = hasNext()
        %return 1 if there is a next.
        if ~isempty(shuffleOnsetAsynchrony) && blockCounter_ > 0
            has = 1;
        else
            has = 0;
        end
    end

    function trial = next(params)
        
        %select a trial from the trials to be done...
        index = ceil(rand() * numel(shuffleOnsetAsynchrony));
        thisDx = shuffleDx(index);
        thisConsistent = shuffleConsistent(index)
        barAsynchrony = shuffleOnsetAsynchrony(index);
        barDisplacement = shuffleFlashDisplacement(index);
        
        rounded = params.cal.interval * round(barAsynchrony / params.cal.interval);
        if abs(rounded - barAsynchrony) > 0.001
            warning('CircleInterpolationTrialGenerator:framesync', 'Specified onset asynchronies are not well aligned to frame intervals!');
        end

        %now randomize the stimulus:
        %onset times are randomized within a window of dt to reduce
        %'strobing' appearance. They are also aligned to frame intervals.
        onsets = params.cal.interval * floor((baseOnset + rand(1, nTargets) * base.getDt()) / params.cal.interval);
        
        if (minGap * nTargets) > 2*pi
            error('circleInterpolationTrialGenerator:nTargets', 'can''t support that minimum gap with that many targets.');
        end
        
        %phase of each target at the time of cue (randomly chooses target
        %locations with the condition that no target is less than minGap
        %from another target.)
        r1 = rand();
        r2 = sort(rand(1, nTargets));
        phases = mod( r1 * 2*pi ...
                      + minGap * (0:(nTargets-1)) ...
                      + r2 * (2*pi - nTargets * minGap)...
                    , 2*pi)
                
        minGap;
        gaps = abs(mod(pi + phases([2:nTargets 1]) - phases, 2*pi) - pi);
        if any(gaps < minGap)
            noop(); %wtf
        end

        %The directions of the targets are randomized except for the first:
        ddx = thisDx * (round(rand(1, nTargets))*2 - 1);
        ddx(1) = thisDx;
        
        %the phase of the bar flash and comparison
        barPhase = phases(1) + barDisplacement/base.getRadius()*sign(thisDx);
        
        %the onset of the flash is determined:
        barOnset = onsets(1) + barAsynchrony;
        
        %and the onset phases are adjusted for the tine the targets spend
        %traveling.
        travel = ddx/base.getRadius().*(barOnset - onsets)./base.getDt();
        phases = mod(phases - travel, 2*pi);

        %and the angles (i.e. the coherences) randomized except fot the
        %first one which is determined;
        angles = phases * 180/pi + 90*sign(ddx) + 180 * round(rand);
        angles(1) = phases(1)*180/pi + 90*sign(thisDx) + 180*~logical(thisConsistent);
        angles = mod(angles, 360);
        
        trial = clone(base ...
            , 'onsets', onsets ...
            , 'phases', phases ...
            , 'dx', ddx ...
            , 'angles', angles ...
            , 'barPhase', barPhase ...
            , 'barOnset', barOnset ...
            );
            
        printf('made a trial: %f dx, %d consistent, %f asynch, %f displacement', ddx(1), thisConsistent, barAsynchrony, barDisplacement);
    end

    function result(last, result)
        %Interprets a trial, and if is has a response removes it from the
        %pending trials list. Note it considers all the targets, whcih is
        %unnecessary but leftover from an earlier version.
        
        thisDx = last.getDx();
        phases = last.getPhases();
        angles = last.getAngles();
        
        thisConsistent = (mod(180 + angles - phases*180/pi , 360) - 180).*sign(thisDx) > 0;
        %which target was nearest the bar when the bar blinked?
        travel = last.getDx()./last.getDt()./last.getRadius().*(last.getBarOnset()-last.getOnsets());
        targetPhasesAtFlash = last.getPhases() + travel;
        last.getBarPhase();
        [tmp, targetIndex] = min(abs(mod(pi + last.getBarPhase() - targetPhasesAtFlash, 2*pi) - pi))
        flashPhaseDisplacement = mod(pi + (last.getBarPhase() - targetPhasesAtFlash) .* sign(thisDx), 2*pi) - pi;
        flashDisplacement= flashPhaseDisplacement * last.getRadius();
        
        asynch = last.getBarOnset() - last.getOnsets();
        
        if ~isfield(result, 'responseDisplacement') || isnan(result.responseDisplacement)
            return;
        end

        printf(' got a trial: %f dx, %d consistent, %f asynch, %f displacement, response displacement %d'...
            , thisDx(targetIndex)...
            , thisConsistent(targetIndex)...
            , asynch(targetIndex)...
            , flashDisplacement(targetIndex)...
            , result.responseDisplacement...
            );

        %check if it matches a scheduled trial and if so remove it.
        match = find ...
            ( (thisDx(targetIndex) == shuffleDx) ...
            & (thisConsistent(targetIndex) == shuffleConsistent) ...
            & (abs(shuffleOnsetAsynchrony - asynch(targetIndex)) < 0.001) ...
            & (abs(flashDisplacement(targetIndex) - shuffleFlashDisplacement) < 0.01));
        
        if ~isempty(match)
            disp match
            shuffleDx(match(1)) = [];
            shuffleConsistent(match(1)) = [];
            shuffleOnsetAsynchrony(match(1)) = [];
            shuffleFlashDisplacement(match(1)) = [];
            numel(shuffleDx)
            blockCounter_ = blockCounter_ - 1;
        else
            disp('No match! Last trial was not found in trial list.');
        end
        
    end

end
