function this = UniformDistribution(varargin)
    %a uniform distribution object, which preserves independent
    %state.

    lower = 0;
    upper = 1;
    
    oldSeed_ = rand('twister');
    rand('twister', sum(100*clock));
    seed = rand('twister');
    rand('twister', oldSeed_);
    %NOTE! seed is useless for recalling what happened in a trial if the
    %save happens _after_ the event. Therefore we dump out structures for
    %trials _before_
    %running them. 
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function r = e(varargin)
        l = ev(lower);
        u = ev(upper);
        rand('twister', seed);
        if nargin < 1
            r = l + rand(size(l)) .* (u - l);
        elseif isnumeric(varargin{1})
            r = l + rand(varargin{:}) .* (u - l);
        else
            r = l + rand(size(l)) .* (u-1);
        end
        seed = rand('twister');
    end
end