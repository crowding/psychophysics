function this = PickNearest(varargin)

    %Simply rounds the input to the nearest value. For use with QUEST as a
    %restriction. Note that if using dither, the set should be in sorted
    %order.

    set = [];
    dither = 0; %add or this much from the index at random.; i.e. dithering=1 might use the previous index 33% of the time or the next index 33% of the time.
    rng = RandStream();
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function out = e(in)
        [x, i] = min(abs(set-in));
        if dither ~= 0
            %perturb the index...
            offset = floor(rng.e() * (2*dither+1)) - dither;
            i = min(max(i+offset, 1), numel(set));
        end
        out = set(i);
    end
    
end