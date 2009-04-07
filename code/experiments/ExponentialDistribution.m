function this = ExponentialDistribution(varargin)
    %a (truncated) exponential distribution object, which preserves
    %independent state.

    offset = 0;
    tau = 1;
    max = Inf;
    rand('twister', sum(100*clock));
    seed = rand('twister');
    %NOTE! seed is useless for recalling state if the
    %save happens after the event. Dump out structures for trials before
    %running them. 
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function r = e(x)
        o = ev(offset);
        t = ev(tau);
        m = ev(max);
        tmp = rand('twister');
        rand('twister', seed);
        r = Inf;
        while r > m %pull values until you get inside the right range.
            r = o - log(rand(size(o))) * t;
        end
        seed = rand('twister');
        rand('twister', tmp);
    end
end