function this = CircularCauchyMotion(varargin)
%Generates the motion of one or many objects appearing circularly in
%apparent motion.
%Each parameter my have a number of columns (corresponding to a number of
%objects) or a number of rows (corresponding to a sequence of appearances,
%that may be repeated. In the case of "color" we have the third dimension
%giving sequencing (as the second is taken.)

    x = 0; %the center around which the sprite rotates
    y = 0;
    radius = 0; %the radius of the circle it/they move on
    phase = 0; %the initial phase
    angle = 0;
    color = [0.5;0.5;0.5];

    wavelength = 1;
    width = 1;
    duration = 0.1;
    velocity = 10;
    localPhase = 0;
    order = 4;

    dphase = 0; %the phase angle change per appearance
    dLocalPhase = 0; %does the local phase angle change?
    dt = 0.1; %the number of seconds per appearance
    n = Inf; %the number of appearances to show (for each item)

    t = 0; %time of the first appearance

    counter_ = [0]; %counts how many of each target have been shown...

    lastT_ = -Inf; %time of the last thing to be shown...

    persistent init__;
    this = autoobject(varargin{:});

%-----

    function r = getRadius()
        r = radius;
    end

    function setPhase(p)
        phase = p;
        counter_ = zeros(size(phase));
    end

    function out = next()
        c = counter_;

        %correct the counter, in case n/t/phase changed.
        ct = counter_;
        ct(:) = floor((lastT_ - t) ./ dt + 1);

        c = min(c, ct+1);
        c = max(c, ct-1);
        c = max(c, 0);

        c(c > n) = NaN;

        %For better efficiency we want to return more than one blob at a time
        %(to cut down on funtion calling overhead.) That way the whole
        %queue can be populated in a couple of calls.  Take each and
        %advance by one step, but strip the ones that

        tt = t + c .* dt;
        i = find(tt <= min(tt + dt));
        tt = tt(i);
%        [tt, ix] = sort(tt);
%        i = i(ix);

%       [tt, i] = min(t + c .* dt);

        if ~isnan(tt)
            %phase + dphase.*c

            xxx = x + radius .* cos(phase + dphase.*c);
            yyy = y - radius .* sin(phase + dphase.*c);
            aaa = angle + 180/pi .* dphase.*c;

            xx = xxx(i);
            yy = yyy(i);
            aa = aaa(i);

            if size(color, 2) > 1
                cc = color(:,i);
            else
                cc = color(:,ones(1,numel(i)));
            end

            if numel(wavelength) > 1
                ll = wavelength(i);
            else
                ll = wavelength(ones(1,numel(i)));
            end

            if numel(width) > 1
                ww = width(i);
            else
                ww = width(ones(1,numel(i)));
            end

            if numel(duration) > 1
                dd = duration(i);
            else
                dd = duration(ones(1,numel(i)));
            end

            if numel(velocity) > 1
                vv = velocity(i);
            else
                vv = velocity(ones(1,numel(i)));
            end

            if numel(localPhase) > 1
                ph = localPhase(i) + dLocalPhase.*c(i);
            else
                ph = localPhase(ones(1,numel(i))) + dLocalPhase.*c(i);
            end

            if numel(order) > 1
                or = order(i);
            else
                or = order(ones(1,numel(i)));
            end

            counter_(i) = c(i) + 1;
            lastT_ = max(tt);

            out = [xx;yy;tt;aa;cc;ww;dd;ll;vv;or;ph];

        else
            out = zeros(13, 0);
        end

%        s = struct('x', xx, 'y', yy, 't', tt, 'angle', aa, 'color', cc, 'wavelength', ll, 'width', ww, 'duration', dd, 'velocity', vv, 'phase', ph, 'order', or);
    end

    function reset()
        counter_ = zeros(size(phase));
        lastT_ = 0;
    end
end