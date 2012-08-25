function this = DotField(varargin)
    x = 0;
    y = 0;
    width = 5;
    height = 5;
    maxDensity = 100; %The maximum number of dot appearances per degree of visual angle per second.
    
    interval = 0; %in frames
    
    density = @one; %a function with domain over X and Y returning the density in a range from 0 to 1
    displacement = @noop; %a function with domain of X and y returning the displacement of each dot.
    coherence = @noop; % a function with density between zero and 1 that determines the probability of a dot jumping according to the displacement. 
    
    dotDelay = 0.04; %if a dot moves, its next appearance is this far in the future.
    
    persistent this__;
    this = autoobject(varargin{:});
    
    dotsX_ = [];
    dotsY_ = [];
    dotsT_ = [];
    lastTime_ = -Inf;
    
    movingdotsX_ = [];
    movingdotsY_ = [];
    movingdotsT_ = [];
    
    onset
    function [dotsX, dotsY, dotsT] = dots(onset) 
        %we need one frame to get started
        if isempty(dotsT_)
            if isinf(lastDot_)
                lastDot_ = onset_;
            end
        end
        %generate exponential dots
    end
end