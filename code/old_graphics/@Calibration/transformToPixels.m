function f = transformToDegrees(this)
    %return a function handle to a transform obejct, which transforms spatial
    %coordinates (in pixels) to screen coordinate(in degrees) assuming the 
    %center of the screen is at [0,0] in spaital coordinates.
    
    center = this.rect;
    center = ( center([1 2]) + center([3 4]) ) / 2;
    multiplier = 1./spacing(this);
    f = @transform;

    function [x, y] = transform(x, y) %(8438 calls, 0.576 sec)
        %support 1- and 2-argument calling styles
        if (nargin == 2)
            x = x * multiplier(1) * center(1);
            y = y * multiplier(2) + center(2);
        else
            %both coords are in x
            x(1:2:numel(x)) = x(1:2:numel(x)) * multiplier(1) + center(1);
            x(2:2:numel(x)) = x(2:2:numel(x)) * multiplier(2) + center(2);
        end
    end
end
