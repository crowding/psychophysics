function this = CircularCauchyMotion(varargin)
    %Generates the motion of one or many objects appearing circularly in
    %apparent motion.
    
    x = 0; %the center around which the grid rotates
    y = 0;
    
    minLogRadius = 0; %the minimum radius to show
    maxLogRadius = log(10); %the maximum radius to show
    
    %restrict to an annulus. even if using the whole 
    %circle there is a discontinuity at the annulus.
    minArcPhase = -pi; 
    maxArcPhase =  pi;
    arcPhaseSkew = 0; %0; ...2/(sqrt(5)-1); %skew per "course" of arcradius
    logRadiusSkew = 0; %(sqrt(5)-1)/2; %per "course" of arcphase
    
    %the spacing of the grid
    logRadiusSpacing = 1;
    arcPhaseSpacing = 2*pi;
    phaseSkew = 0; %around the whole circle, that is 
    phaseSkewR = 0; %per radial course
    
    %the particular starting point
    logRadius = 0;
    arcPhase = 0;
    localPhase = 0;
    
    %how the vortex grid moves per step
    dLogRadius = 0;
    dArcPhase = 0;
    dLocalPhase = 0; %does the local phase angle change?
    
    angle = 0; % the angle of each beast (relative to a radial line)
    
    color = [0.5;0.5;0.5];
    
    %all of these are multiplied by radius
    wavelength_mult = 0.1; %
    width_mult = 0.1; %
    velocity_mult = 1; %
    
    duration = 0.1;
    order = 4;
    
    dt = 0.1; %the number of seconds per appearance

    t = 0; %time of the first appearance

    counter_ = 0; %counts how many have been shown...

    persistent init__;
    this = autoobject(varargin{:});

%-----
    function resetCounter()
        %adjust things and put the counter back to zero. Needed before
        %adjusting dLogPhase, spacing, wrapping, etc.
        logRadius = wrap(logRadius + counter_ * dLogRadius, minLogRadius, logRadiusSpacing);
        arcPhase = wrap(arcPhase + counter_ * dArcPhase, minArcPhase, arcPhaseSpacing);
        t = t + counter_ * dt;
        localPhase = localPhase + dLocalPhase.*counter_;
        counter_ = 0;
    end

    function out = nextStruct()
        error('not implemented');
    end

    function out = next()
        %grid up all the blobs
        
        [thisArcPhase, thisLogRadius] = ndgrid...
            ( wrap(arcPhase + counter_ * dArcPhase, minArcPhase, arcPhaseSpacing):arcPhaseSpacing:maxArcPhase ...
            , wrap(logRadius + counter_ * dLogRadius, minLogRadius, logRadiusSpacing):logRadiusSpacing:maxLogRadius ...
            );

        if numel(thisArcPhase) >= 1 && abs(thisArcPhase(1,1) - thisArcPhase(end,1) + 2*pi) < 0.001
            thisArcPhase(end,:) = [];
            thisLogRadius(end,:) = [];
        end
        
        thisLogRadius = thisLogRadius(:)';
        thisArcPhase  = thisArcPhase(:)';
        
        thisLogRadius1 = thisLogRadius + mod(logRadiusSkew .* logRadiusSpacing./arcPhaseSpacing .* (thisArcPhase-arcPhase - counter_*dArcPhase), logRadiusSpacing);
        thisLogRadius = thisLogRadius1;
        thisArcPhase1 = thisArcPhase + arcPhaseSkew .* arcPhaseSpacing./logRadiusSpacing .* (thisLogRadius-logRadius - counter_*dLogRadius);
        thisArcPhase = thisArcPhase1;
        
        xx = x + exp(thisLogRadius) .* cos(thisArcPhase);
        yy = y - exp(thisLogRadius) .* sin(thisArcPhase);
        tt = t(:,ones(1,numel(xx))) + counter_ * dt;
        aa = thisArcPhase.*180/pi + 90 + angle;
        cc = color(:,ones(1,numel(xx)));
        ll = wavelength_mult(ones(1,numel(xx))) .* exp(thisLogRadius);
        ww = width_mult(ones(1,numel(xx))) .* exp(thisLogRadius);
        dd = duration(ones(1,numel(xx)));
        vv = velocity_mult(ones(1,numel(xx))) .* exp(thisLogRadius);
        or = order(ones(1,numel(xx)));
        ph = localPhase(ones(1,numel(xx))) + dLocalPhase.*counter_ + phaseSkew .* thisArcPhase + 2*pi*phaseSkewR .* thisLogRadius/logRadiusSpacing;
        
        counter_ = counter_ + 1;
        
        out = [xx;yy;tt;aa;cc;ww;dd;ll;vv;or;ph];
    end

    function pos = currentPosition(time)
        count = round((time - t)/dt);
        
        thisArcPhase = wrap(arcPhase + count * dArcPhase, minArcPhase, floor((maxArcPhase-minArcPhase)/arcPhaseSpacing)*arcPhaseSpacing);
        thisLogRadius = wrap(logRadius + count * dLogRadius, minLogRadius, floor((maxLogRadius-minLogRadius) / logRadiusSpacing)*logRadiusSpacing);
        
        %thisLogRadius1 = thisLogRadius + mod(logRadiusSkew .* logRadiusSpacing./arcPhaseSpacing .* (thisArcPhase-arcPhase - counter_*dArcPhase), logRadiusSpacing);
        %thisLogRadius = thisLogRadius1;
        %thisArcPhase1 = thisArcPhase + arcPhaseSkew .* arcPhaseSpacing./logRadiusSpacing .* (thisLogRadius-logRadius - counter_*dLogRadius);
        %thisArcPhase = thisArcPhase1;
        
        xx = x + exp(thisLogRadius) .* cos(thisArcPhase);
        yy = y - exp(thisLogRadius) .* sin(thisArcPhase);
        
        pos = [xx;yy];
    end

    function r = currentSize(time)
        count = round((time - t)/dt);
        %let's just say 1.5 times the log radius
        thisLogRadius = wrap(logRadius + count * dLogRadius, minLogRadius, floor((maxLogRadius-minLogRadius) / logRadiusSpacing)*logRadiusSpacing);
        r = 0.75 * width_mult .* exp(thisLogRadius);
    end

    function reset()
        n_ = 0;
    end
end