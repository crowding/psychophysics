function this = EyeVelocityFilter(varargin)
    %Filters the position and velocity of the raw eye position. Adds fields
    %eyeFx, eyeFy, eyeFt, eyeVx, eyeVy, eyeVt 

    %should be placed in INPUT list, after the input that gives eye
    %position.

    cutoff = 100; %Position filter cutoff in Hz
    order = 4; %the order of the positionfilter.
    
    vcutoff = 25; %cutoff of the velocity filter
    vorder = 5; %order of the velocity filter

    log = @noop; %log not used...
    
    persistent init__;
    this = autoobject(varargin{:});
    
    interval_ = NaN;
    delay_ = 0;
    vdelay_ = 0;
    
    a_ = [];
    b_ = [];
    va_ = [];
    vb_ = [];
    
    stateX_ = [];
    stateY_ = [];
    stateVx_ = [];
    stateVy_ = [];
    
    lastX_ = 0; %last X value for differentiation
    lastY_ = 0; %last Y value for differentiation
    
    function [release, params] = init(params)
        [release, params] = begin(params);
    end

    function [release, params] = begin(params)
        %called when experiment input begins...
        rate = params.eyeSampleRate;
        interval_ = 1/rate;
        %make a Butterworth filter with the appropriate cutoff...
        [b_, a_] = butter(order, cutoff*2/rate);
        [vb_, va_] = butter(vorder, vcutoff*2/rate);
        stateX_ = [];
        stateY_ = [];
        
        %approximate the filter delay with the group delay at 0 Hz
        delay_ = mean(grpdelay(b_,a_,[0 0],1000)) * interval_;
        vdelay_ = mean(grpdelay(vb_,va_,[0 0],1000)) * interval_ + interval_/2;
        
        %called at the start of each trial
        stateVx_ = filtic(vb_, va_, zeros(size(vb_)), zeros(size(va_)));
        stateVy_ = filtic(vb_, va_, zeros(size(vb_)), zeros(size(va_)));
        
        release = @cl;
        function cl
            stateX_ = [];
            stateY_ = [];
            lastX_ = [];
            lastY_ = [];
            stateVx_ = [];
            stateVy_ = [];
        end
    end

    function sync(frame, time)
        %no sync required
    end

    function event = check(event)
        event = input(event);
    end

    function event = input(event)
        %filter and add eye velocity fields to the event
        
        if ~isempty(event.eyeX)
            %Remove NaNs before filtering, since the IIR filters
            %propagate NANs.
            numbers = ~isnan(event.eyeX);
            x = event.eyeX(numbers);
            y = event.eyeY(numbers);
            t = event.eyeT(numbers);

            if ~isempty(x)
                if isempty(stateX_)
                    %At the start of the trial pretend there is a
                    %constant boundary condition.
                    lastX_ = x(1);
                    lastY_ = y(1);
                    stateX_ = filtic(b_, a_, zeros(size(b_)) + x(1), zeros(size(a_)) + x(1));
                    stateY_ = filtic(b_, a_, zeros(size(b_)) + y(1), zeros(size(a_)) + y(1));
                end

                %filtered position
                [event.eyeFx, stateX_] = filter(b_, a_, x, stateX_);
                [event.eyeFy, stateY_] = filter(b_, a_, y, stateY_);
                event.eyeFt = t - delay_;
                
                %raw derivative
                vx = (x - [lastX_ x(1:end-1)]) / interval_;
                vy = (y - [lastY_ y(1:end-1)]) / interval_;

                %filtered derivative
                [event.eyeVx, stateVx_] = filter(vb_, va_, vx, stateVx_);
                [event.eyeVy, stateVy_] = filter(vb_, va_, vy, stateVy_);
                [event.eyeVt] = (t - vdelay_);
                
                lastX_ = x(end);
                lastY_ = y(end);
            else
                [event.eyeFx,event.eyeFy,event.eyeFt,event.eyeVx,event.eyeVy,event.eyeVt] = deal(zeros(0,1));
            end
        else
            [event.eyeFx,event.eyeFy,event.eyeFt,event.eyeVx,event.eyeVy,event.eyeVt] = deal(zeros(0,1));
        end
    end
end