function this = UniformDistribution(varargin)
    %a uniform distribution object, which preserves independent
    %state.

    lower = 0;
    upper = 1;
    rand('twister', sum(100*clock));
    seed = rand('twister');
    %NOTE! seed is useless for recalling state if the
    %save happens after the event. Dump out structures for trials before
    %running them. 
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function r = e(x)
        l = ev(lower);
        u = ev(upper);
        rand('twister', seed);
        r = l + rand(size(l)) .* (u - l);
        seed = rand('twister');
    end
end