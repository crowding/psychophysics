function this = CircleInterpolationTrialGenerator(varargin)
    %Generate trials that explore interpolation (response using the mouse.)

    nDistractors = 5;
    radius = 10;
    dx = 0.75;
    dt = 0.15;
    nStations = 5;
    onsetAsynchronies = linspace(0, 2*dt, 10); %default value.
    flashDisplacements = linspace( -dx/2, 2.5*dx, 10 ); %default value.
    
    patch = CauchyPatch...
        ( 'velocity', 5 ...
        , 'size', [0.5 0.75 0.1]...
        );
    %------------------ private variables...
    
    shuffleOnsetAsynchrony = [];
    shuffleFlashDisplacement = [];
    shuffleConsistent = [];
    shuffleDx = [];

    shuffle_();
    
    this = autoobject(varargin{:});

    %------------------ methods...

    function n = setOnsetAsynchronies(n)
        onsetAsynchronies = n;
        
        shuffle_();
    end

    function n = setFlashDisplacements(n)
        flashDisplacements = n;
        shuffle_();
    end

    function shuffle_()
        [soa, sfd, sc, sdx] = ndgrid(onsetAsynchronies, flashDisplacements, [0 1], [dx -dx]);
        shuffleOnsetAsynchrony = soa(:);
        shuffleFlashDisplacement = sfd(:) .* sign(sdx(:));
        shuffleConsistent = sc(:);
        shuffleDx = sdx(:);
    end

    function has = hasNext()
        %return 1 if there is a next.
        if ~isempty(shuffleOnsetAsynchrony)
            has = 1;
        else
            has = 0;
        end
    end

    function trial = next(params)

        index = ceil(rand() * numel(shuffleOnsetAsynchrony));
        
        thisDx = shuffleDx(index);
        thisConsistent = shuffleConsistent(index);

        barAsynchrony = shuffleOnsetAsynchrony(index);
        
        rounded = params.cal.interval * round(barAsynchrony / params.cal.interval);
        if abs(rounded - barAsynchrony) > 0.001
            warning('CircleInterpolationTrialGenerator:framesync', 'Specified onset asynchronies are not well aligned to frame intervals!');
        end
        
        barDisplacement = shuffleFlashDisplacement(index);

        %onset times of each thing (staggering the onset times reduces the
        %appearance of strobing)
        onsets = dt + (0:nDistractors-1) * dt / nDistractors;
        
        %align to frame intervals
        onsets = params.cal.interval * floor(onsets / params.cal.interval);

        %phases of each thing (note, this produces an irregular, but
        %non-overlapping distribution.
        phases = (rand() + (0:nDistractors-1)/nDistractors)*2*pi;
        phases = phases + rand(1, nDistractors) * pi/nDistractors;
        phases = phases(randperm(length(phases)));

        %randomly choose one of the items as the target
        targetIndex = ceil(rand() * nDistractors);

        %set the bar onset asynchrony
        p = patch;
        p.velocity = p.velocity * sign(thisDx) * 2 *(logical(thisConsistent) - 0.5);

        trial = CircleInterpolationTrial ...
            ( 'dx', thisDx ...
            , 'dt', dt ...
            , 'n', nStations ...
            , 'onsets', onsets ...
            , 'phases', phases ...
            , 'barPhase', phases(targetIndex) + barDisplacement/radius...
            , 'barOnset', onsets(targetIndex) + barAsynchrony ...
            , 'patch', p ...
            );
        
        printf('made a trial: %f dx, %d consistent, %f asynch, %f displacement', thisDx, thisConsistent, barAsynchrony, barDisplacement);
    end

    function result(last, result)
        %TODO: Interpret a mixed up clockwise and counter; leftward and rightward.

        %This is probably the har way to do it... backing out the
        %rights data from the raw stimulus (when I could have just
        %saved the raw data... but it makes sure that the data I save
        %is sufficient & my task is unambiguous.
        
        thisDx = last.getDx();
        p = last.getPatch();
        thisConsistent = sign(p.velocity / last.getDx()) > 0;

        %find the right quest and update it
        %THIS ISN'T QUITE RIGHT...
        %which target was nearest the bar when the bar blinked?
        targetPhasesAtOnset = last.getPhases() + last.getDx()/last.getRadius()*last.getBarOnset();
        [tmp, targetIndex] = min(abs(last.getBarPhase() - targetPhasesAtOnset));
        targetPhaseDisplacement = last.getBarPhase() - last.getPhases(); %dsplacement for initial target appearance.
        targetPhaseDisplacement = targetPhaseDisplacement(targetIndex);
        targetDisplacement = targetPhaseDisplacement * last.getRadius();
        
        asynch = last.getBarOnset() - last.getOnsets();
        asynch = asynch(targetIndex);
        [tmp, questIndex] = min(abs(asynch - onsetAsynchronies));

        if ~isfield(result, 'responseDisplacement') || isnan(result.responseDisplacement)
            return;
        end

        printf(' got a trial: %f dx, %d consistent, %f asynch, %f displacement, response displacement %d', thisDx, thisConsistent, asynch, targetDisplacement, result.responseDisplacement);

        %check if it matches a scheduled trial and if so remove it.
        match = find((thisDx == shuffleDx) & (thisConsistent == shuffleConsistent) & (abs(shuffleOnsetAsynchrony - asynch) < 0.001) & (abs(targetDisplacement - shuffleFlashDisplacement) < 0.01));
        if ~isempty(match)
            disp match
            shuffleDx(match(1)) = [];
            shuffleConsistent(match(1)) = [];
            shuffleOnsetAsynchrony(match(1)) = [];
            shuffleFlashDisplacement(match(1)) = [];
            numel(shuffleDx)
        else
            disp('No match! Last trial was not found in trial list.');
        end
        
    end

end