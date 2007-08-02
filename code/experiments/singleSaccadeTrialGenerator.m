function this = DoubleSaccadeTrialGenerator(varargin)
    
    %Use a 'base' object which contains the basic parameters that don't
    %change.
    base = SingleSaccadeTrial();

    %these are the parameters we randomize on
    n = 3;
    radius = 10;
    dx = .75;
    dt = 0.15;
    
    this = autoobject(varargin{:});
    
    function h = hasNext()
        h = 1;
    end

    function result(last, result)
        %interpret the last result, if it needs interpretation
        %which it doesn't really
    end

    function trial = next(params)
        cue = base.getCue();
        
        interval = params.cal.interval;
        motionangle = rand(1, n) * 360;
        positions  = (rand() + (0:n-1)/n + 1/(2*n)*rand(1, n)) * 2 * pi;
        
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
    
        trial = clone(base...
            , 'dx', ddx...
            , 'dy', ddy...
            , 'dt', ddt...
            , 'onsetX', onsetX...
            , 'onsetY', onsetY...
            , 'onsetT', onsetT...
            , 'orientation', orientation...
            );
    end

end