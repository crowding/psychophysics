function this = CircleInterpolationTrialGenerator(varargin)

    nDistractors = 5;
    radius = 10;
    dx = 0.75;
    dt = 0.15;
    nStations = 5;
    onsetAsynchronies = linspace(dt*1.5, dt*2.5, 9); %default value.
    
    quests = []; %this holds data for the QUESTs.
    
    patch = CauchyPatch...
        ( 'velocity', 5 * (round(rand)*2-1) ...
        , 'size', [0.5 0.75 0.1]...
        );

    setupQuests_();
    this = autoobject(varargin{:});

    %------------------ private variables...
    
    questIndex_ = 0;
    
    %------------------ methods...

    function n = setOnsetAsynchronies(n)
        onsetAsynchronies = n;
        
        setupQuests_();
    end

    function setupQuests_()
        quests = arrayfun(@makeQuest, onsetAsynchronies, 'UniformOutput', 0);
        
        function q = makeQuest(asynchrony)
            tGuess = dx/dt * asynchrony;
            tGuessSD = 3 * dx;
            pThreshold=0.5;
            beta=3.5;
            delta=0.01;
            gamma=0.0;
            q = QuestCreate(tGuess, tGuessSD, pThreshold, beta, delta, gamma);
        end
    end

    function has = hasNext()
        %posssibly this will stop when all staircases have converged
        has = 1;
    end

    function trial = next(params, last, result)
        %If we have a last trial and result, update our data.
        if exist('last', 'var') && ~isempty(last) && exist('result', 'var') && ~isempty(result)
            interpret(last, result);
        end
        
        %rotate through all the quests
        questIndex_ = questIndex_ + 1;
        if questIndex_ > numel(quests)
            questIndex_ = 1;
        end
        
        %get a suggestion for the most informative next value.
        barDisplacement = QuestQuantile(quests{questIndex_}, 0.5);
        
        %TODO: mix up clockwise and counter; leftward and rightward
        thisDx = dx; % * (round(rand())*2 - 1);

        barAsynchrony = onsetAsynchronies(questIndex_);
        barAsynchrony = params.cal.interval * floor(barAsynchrony / params.cal.interval);
        
        printf('generating a trial: %f asynch, %f displacement', barAsynchrony, barDisplacement);

        %computed properties
        %onset times of each thing
        onsets = dt + (0:nDistractors-1) * dt / nDistractors;
        %adjust for frame intervals
        onsets = params.cal.interval * floor(onsets / params.cal.interval);

        %phases of each thing
        phases = (rand() + (0:nDistractors-1)/nDistractors)*2*pi;
        phases = phases + rand(1, nDistractors) * pi/nDistractors;
        %phases = rand(1, nDistractors)*2*pi;
        phases = phases(randPerm(length(phases)));

        %randomly choose one of the items as the target
        targetIndex = ceil(rand() * nDistractors);

        %set the bar onset asynchrony
        p = patch;
        p.velocity = p.velocity * (round(rand)*2-1);

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
    end

    function interpret(last, result)
        %TODO: Interpret a mixed up clockwise and counter; leftward and rightward.

        %This is probably the har way to do it... backing out the
        %rights data from the raw stimulus (when I could have just
        %saved the raw data... but it makes sure that the data I save
        %is sufficient & my task is unambiguous.
        
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
        if isnan(result.ahead)
            return;
        end

        printf('got a trial: %f asynchrony, %f displacement, response %d', asynch, targetDisplacement, result.ahead);

        quests{questIndex} = QuestUpdate(quests{questIndex}, targetDisplacement, result.ahead);
    end

end