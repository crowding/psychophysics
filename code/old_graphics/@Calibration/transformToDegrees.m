function f = transformToDegrees(this)
    %return a function handle to a transform function, which transforms screen
    %coordinates (in pixels) to spatial coordinates (in degrees) assuming the 
    %center of the screen is at [0,0] in spatial coordinates.
    
    center = this.rect;
    center = ( center([1 2]) + center([3 4]) ) / 2;
    multiplier = spacing(this); %centimeters per pixel
    multiplier = multiplier / this.distance * 180 / pi; %degrees per pixel AT SCREEN CENTER
    
    f = @transform;

    function [x, y] = transform(x, y)
        %support 1- and 2-argument calling styles
        if (nargin == 2)
            
            x = (x - center(1)) .* multiplier(1);
            y = (y - center(2)) .* multiplier(2);

            corr = 1;
            %corr = atand(x.^2 + y.^2)
            x = x * corr;
            y = y * corr;
        else
            %both coords are in x
            if all(size(x) == [1 2])
                x = (x - center) .* multiplier;
            else
                x = (x - repmat(center, size(x, 1), size(x,2)/2))...
                         .* repmat(multiplier, size(x, 1), size(x, 2)/2);
            end
            
            %todo: no correction.
        end
    end
end
