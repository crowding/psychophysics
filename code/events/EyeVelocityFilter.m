function this = EyeVelocityFilter(varargin)
    %Adds fields 'eyeVx' and 'eyeVy' which contain filtered velocity
    %traces.

    %should be placed in INPUT list, after the input that gives eye
    %position.

    cutoff = 60; %filter cutoff in Hz
    order = 5; %the order of the filter.
    
    this = autoobject(varargin{:})
    
    interval_ = NaN;
    nstate_ = 0;
    delay_ = 0;
    log = @noop; %log not used...
    
    a_ = [];
    b_ = [];
    
    stateX_ = [];
    stateY_ = [];
    
    function [release, params] = init(params)
        %called when experiment input begins...
        rate = params.eyeSampleRate;
        interval_ = 1/rate;
        %make a Butterworth filter with the appropriate cutoff...
        [b_, a_] = butter(order, cutoff*2/rate);
        stateX_ = [];
        stateY_ = [];
        nstate_ = max(length(b_), length(a_)) - 1;
        
        %approximate the filter delay with the group delay at 0 Hz plus the
        %filter length
        
        delay = nstate_ * interval + 
        
        %test this with a filtering...
        
        
        release = @cl;
        function cl
            stateX_ = [];
            stateY_ = [];
        end
    end

    function draw(window, toPixels)
        %nothing
    end

    function event = input(event)
        %filter and add eye velocity fields to the event
        
        if ~isempty(event.eyeX)
            if isempty(stateX_)
                %Initial condition of continuation...
                stateX_ = zeros(1, nstate_) + event.eyeX(1);
                stateY_ = zeros(1, nstate_) + event.eyeY(1);
            end

            [event.eyeVx, stateX_] = filter(b_, a_, event.eyeX, stateX_);
            [event.eyeVy, stateY_] = filter(b_, a_, event.eyeY, stateY_);
            event.eyeVt = eyent.eyeT + delay;
        else
            event.eyeX = zeros(1,0);
            event.eyeY = zeros(1,0);
            event.eyeT = zeros(1,0);
        end
    end
end