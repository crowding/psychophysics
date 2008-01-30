function this = ExponentialDistribution(varargin)
    %an exponential distribution object, which preserves independent
    %state.

    offset = 0;
    tau = 1;
    seed = rand('twister');
    %NOTE! seed is useless for recalling state if the
    %save happens after the event. Dump out structures for trials before
    %running them. 
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function r = e(x)
        o = ev(offset);
        t = ev(tau);
        rand('twister', seed);
        r = o - log(rand(size(o))) * t;
        seed = rand('twister');
    end
end