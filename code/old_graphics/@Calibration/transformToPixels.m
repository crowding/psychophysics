function f = transformToDegrees(this)
    %return a function handle to a transform obejct, which transforms spatial
    %coordinates (in pixels) to screen coordinate(in degrees) assuming the 
    %center of the screen is at [0,0] in spaital coordinates.
    
    center = this.rect;
    center = ( center([1 2]) + center([3 4]) ) / 2;
    multiplier = 1./spacing(this);
    f = @transform;

    function [x, y] = transform(x, y)
        %support 1- and 2-argument calling styles
        if (nargin == 2)
            loc = [x y];
            loc = loc .* multiplier + center;
            x = loc(1);
            y = loc(2);
        else
            %both coords are in x
            if isequal(size(x), [1 2])
                x = x .* multiplier + center;
            else
                x = x .* reshape(repmat(multiplier, 1, numel(x) / 2), size(x)) ...
                      +  reshape(repmat(center, 1, numel(x) / 2), size(x));
%                x = x .* repmat(multiplier, numel(x, 1), size(x,2)/2)...
%                         + repmat(center, size(x, 1), size(x, 2)/2);
            end
        end
    end
end
