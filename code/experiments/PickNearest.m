function this = PickNearest(varargin)

    %Simply rounds the input to the nearest value. For use with QUEST as a
    %restriction.

    set = [];
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function out = e(in)
        [x, i] = min(abs(set-in));
        out = set(i);
    end
    
end