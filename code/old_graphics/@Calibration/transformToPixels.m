function f = transformToPixels(this)
    %return a function handle to a transform function, which transforms spatial
    %coordinates (in degrees) to screen coordinate(in pixels) assuming the 
    %center of the screen is at [0,0] in spatial coordinates.
    %
    %does NOT perform a correction for eccentricity being nonlinear with
    %screen distance.
        
    center = this.rect;
    center = ( center([1 2]) + center([3 4]) ) / 2;
    
    %multiplier gives degrees per pixel AT SCREEN CENTER
    multiplier = 1./spacing(this); %centimeters per pixel
    multiplier = multiplier * (this.distance) / 180*pi; %centimeters per degree
    f = @transform;

    function [x, y] = transform(x, y) %(8438 calls, 0.576 sec)
        %support 1- and 2-argument calling styles
        if (nargin == 2)
            %trig correction
            %corr = tand(sqrt(x.^2 + y.^2));
            corr = 1;
            
            x = x.*corr * multiplier(1) + center(1);
            y = y.*corr * multiplier(2) + center(2);
        else
            %both coords are in x
            %corr = tand(sqrt(x(1:2:end).^2 + x(2:2:end).^2));
            corr = 1;
            
            x(1:2:end) = x(1:2:end).*corr * multiplier(1) + center(1);
            x(2:2:end) = x(2:2:end).*corr * multiplier(2) + center(2);
            
            %todo: no correction.
        end
    end
end
