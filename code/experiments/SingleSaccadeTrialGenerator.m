function this = SingleSaccadeTrialGenerator(varargin)
    
    %Use a 'base' object which contains the basic parameters that don't
    %change.
    base = SingleSaccadeTrial;

    %these are the parameters we randomize on
    n = 3;
    radius = 10;
    excluded = 5; %targets will not be anywhere less than this distance from the fixation point...
    dx = 0.75;
    dt = 0.15;
    contrast = 1;
    cueMin = 0.2;
    cueMax = 1.0;
    cueJumpAmplitude = 0.1;
    numInBlock = 50;
    
    this = autoobject(varargin{:});

    function result(last, result)
        %interpret the last result, if it needs interpretation
        %which it doesn't really
        if (isfield(result, 'success') && result.success)
            blockCounter_ = blockCounter_ - 1
        end
    end

    blockCounter_ = 0;
    function startBlock()
        blockCounter_ = numInBlock
    end

    function has = hasNext()
        %return 1 if there is a next.
        if blockCounter_ > 0
            has = 1;
        else
            has = 0;
        end
    end

    function trial = next(params)
        %randomize the trial...
        
        cue = (cueMax - cueMin) * rand() + cueMin;

        %Some sanity checking -- make sure the objects to not go off the
        %screen during the trial.
        t = transformToDegrees(params.cal);
        d = min(abs(t(params.cal.rect))); %max usable eccentricity on screen

        %which angle window do we need to exclude to keep the targets away
        %from the fixation point at the beginning of the trial?
        x = dx/dt * cue; %max. distance traversed before cue
        if excluded > radius
            error('SingleSaccadeTrialGenerator:params', 'excluded can''t be larger than radius');
        elseif (x + excluded < radius)
            excludedBeginning = 0;
        elseif (x^2 > radius^2 - excluded^2)
            excludedBeginning = asin(excluded/radius) * 360/pi;
        else
            excludedBeginning = acos((radius^2 + x^2 - excluded^2) / (2*radius * x)) * 360/pi;
        end
        
        %which angle window do we need to exclude to keep the target on
        %screen at the end of the trial?
        y = dx/dt * (base.getSaccadeMaxLatency() + base.getTargetSaccadeSettle() + base.getTargetTrackingDuration());
        if radius + y < d
            excludedEnd = 0;
        elseif d + y < radius
            error('SingleSaccadeTrialGenerator:params', 'screen is too small for these parameters');
        else
            excludedEnd = 360 - 180/pi * 2*acos(-(d^2-y^2-radius^2)/2/radius/y);
        end
        
        %which angle window to keep the target on screen at the beginning?
        if radius + x < d
            excludedBeginning = max(excludedBeginning, 0);
        elseif d + x < radius
            error('SingleSaccadeTrialGenerator:params', 'screen is too small for these parameters');
        else
            excludedBeginning = max(excludedBeginning, 360 - 180/pi * 2*acos(-(d^2-x^2-radius^2)/2/radius/x));
        end
        
        if (excludedBeginning + excludedEnd > 360)
            error('SingleSaccadeTrialGenerator:params', 'can''t keep target on screen with these params');
        end
        
        interval = params.cal.interval;
        positions  = (rand() + (0:n-1)/n + 1/(2*n)*rand(1, n)) * 2 * pi;
        cueJump = cueJumpAmplitude * [cos(positions(1)) -sin(positions(1))];
        s = (round(rand) - 0.5)*2;
        motionangle = positions*180/pi + s*(excludedEnd + rand(1,n)*(360-excludedEnd-excludedBeginning))/2;
        
        ddx = dx .* cos(motionangle/180*pi);
        ddy = - dx .* sin(motionangle/180*pi);
        ddt = zeros(1, n) + dt;

        orientation = motionangle - 180 * round(rand(1, n));

        patchDuration = base.getPatch();
        patchDuration = patchDuration.size(3);
        
        onsetT = round(rand(1, n) .* dt / params.cal.interval) * interval + patchDuration;
        onsetX = cos(positions) * radius;
        onsetY = -sin(positions) * radius;
        
        %they should intercept the edge of the circle at cue time. Cue is
        %beasured from onsetT(1).
        onsetX = onsetX - (cue - onsetT + onsetT(1)) .* ddx./ddt;
        onsetY = onsetY - (cue - onsetT + onsetT(1)) .* ddy./ddt;
        
        color = zeros(3, n) + contrast/2;    
        
        trial = clone(base...
            , 'cue', cue...
            , 'cueJump', cueJump...
            , 'dx', ddx...
            , 'dy', ddy...
            , 'dt', ddt...
            , 'onsetX', onsetX...
            , 'onsetY', onsetY...
            , 'onsetT', onsetT...
            , 'orientation', orientation...
            , 'color', color ...
            );
    end

end