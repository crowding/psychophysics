function this = SingleSaccadeTrialGenerator(varargin)
    
    %Use a 'base' object which contains the basic parameters that don't
    %change.
    base = SingleSaccadeTrial...
        ( 'patch', CauchyPatch ...
            ( 'size', [1/3 0.5 0.1] ...
            , 'velocity', 10/3 ... 
            ) ...
        );

    %these are the parameters we randomize on
    n = 3;
    radius = 6.66;
    excluded = 3.33; %targets will not be less than this distance from the fixation point...
    dx = 0.5;
    dt = 0.15;
    contrast = 1;
    
    this = autoobject(varargin{:});
    
    function h = hasNext()
        h = 1;
    end

    function result(last, result)
        %interpret the last result, if it needs interpretation
        %which it doesn't really
    end

    function trial = next(params)

        %Some sanity checking -- make sure the objects to not go off the
        %screen during the trial.
        maxDistance = radius + dx + dx/dt * (base.getSaccadeMaxLatency() + base.getSaccadeTrackDuration())
        t = transformToDegrees(params.cal);
        d = min(abs(t(params.cal.rect)))
        
        
        %note this is not quite the right calculation, since there is
        %the excluded window, but it is an upper bound
        if (maxDistance > d)
            warning('singleSaccadeTrialGenerator:params', 'targets may track off screen with these parameters');
        end

        %randomize the trial...
        
        cue = base.getCue();
        
        %which angle window do we need to exclude to keep the targets away
        %from the fixation point?
        x = dx/dt * cue; %max. distance traversed before cue
        if (x + excluded < radius)
            excludedMotionAngle = 0
        elseif (x^2 > radius^2 - excluded^2)
            excludedMotionAngle = asin(excluded/radius) * 360/pi
        else
            excludedMotionAngle = acos((radius^2 + x^2 - excluded^2) / (2*radius * x)) * 360/pi
        end
        
        interval = params.cal.interval;
        positions  = (rand() + (0:n-1)/n + 1/(2*n)*rand(1, n)) * 2 * pi;
        motionangle = positions * 180/pi + 180 + (rand(1, n) - 0.5) * (360 - excludedMotionAngle);
        
        ddx = dx .* cos(motionangle/180*pi);
        ddy = - dx .* sin(motionangle/180*pi);
        ddt = zeros(1, n) + dt;

        orientation = motionangle - 180 * round(rand(1, n));

        onsetT = round(rand(1, n) .* dt / params.cal.interval) * interval;
        onsetX = cos(positions) * radius;
        onsetY = -sin(positions) * radius;
        
        %they should intercept the edge of the circle at cue time.
        onsetX = onsetX - (cue - onsetT) .* ddx./ddt;
        onsetY = onsetY - (cue - onsetT) .* ddy./ddt;
        
        color = zeros(3, n) + contrast/2;
    
        %TODO: make sure the targets to not go off the screen ...
        
        trial = clone(base...
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