function this = EyeVelocityFilter(varargin)
    %Adds fields 'eyeVx' and 'eyeVy' which contain filtered velocity
    %traces.

    %should be placed in INPUT list, after the input that gives eye
    %position.

    cutoff = 100; %filter cutoff in Hz
    order = 6; %the order of the filter.
    log = @noop; %log not used...
    
    persistent init__;
    this = autoobject(varargin{:});
    
    interval_ = NaN;
    delay_ = 0;
    
    a_ = [];
    b_ = [];
    
    stateX_ = [];
    stateY_ = [];
    stateVx_ = [];
    stateVy_ = [];
    lastX_ = 0;
    lastY_ = 0;
    
    function [release, params] = init(params)
        %called when experiment input begins...
        rate = params.eyeSampleRate;
        interval_ = 1/rate;
        %make a Butterworth filter with the appropriate cutoff...
        [b_, a_] = butter(order, cutoff*2/rate);
        stateX_ = [];
        stateY_ = [];
        
        %approximate the filter delay with the group delay at 0 Hz
        delay_ = mean(grpdelay(b_,a_,[0 0],1000)) * interval_;
        
        release = @cl;
        function cl
            stateX_ = [];
            stateY_ = [];
        end
    end

    function [release, params] = begin(params)
        %called at the start of each trial
        release = @noop;
        stateVx_ = filtic(b_, a_, zeros(size(b_)), zeros(size(a_)));
        stateVy_ = filtic(b_, a_, zeros(size(b_)), zeros(size(a_)));
    end

    function sync(frame)
        %no synch required
    end

    function event = input(event)
        %filter and add eye velocity fields to the event
        
        if ~isempty(event.eyeX)
            %Remove NaNs before filtering, since the IIR filter
            %propagates NANs.
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

                %filtered position and first derivative.
                [event.eyeFx, stateX_] = filter(b_, a_, x, stateX_);
                [event.eyeFy, stateY_] = filter(b_, a_, y, stateY_);
                event.eyeFt = t - delay_;

                vx = (event.eyeFx - [lastX_;event.eyeFx(1:end-1)]) / interval_;
                vy = (event.eyeFy - [lastY_;event.eyeFy(1:end-1)]) / interval_;

                [event.eyeVx, stateVx_] = filter(b_, a_, vx, stateVx_);
                [event.eyeVy, stateVy_] = filter(b_, a_, vy, stateVy_);
                [event.eyeVt] = (event.eyeFt - interval_/2 - delay_);
                
                lastX_ = event.eyeFx(end);
                lastY_ = event.eyeFy(end);
            else
                [event.eyeFx,event.eyeFy,event.eyeFt,event.eyeVx,event.eyeVy,event.eyeVt] = deal(zeros(0,1));
            end
        else
            [event.eyeFx,event.eyeFy,event.eyeFt,event.eyeVx,event.eyeVy,event.eyeVt] = deal(zeros(0,1));
        end
    end
end