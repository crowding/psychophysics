function this = CircularSmoothCauchyMotion(varargin)

%plots a cauchy blob moving smoothly around a circle.

x = 0; %the center around which the sprite rotates
y = 0;
radius = 5; %the radius of the circle it/they move on
phase = 0; %the initial phase
angle = 0; %the initial angle
color = [0.5;0.5;0.5];

wavelength = 1;
width = 1;
omega = 1/2;
localPhase = 0;
order = 4;

persistent init__;
this = autoobject(varargin{:});
    
    function [xy, a, l, o, w, c, ph] = get(next, frame)
        xy = [radius * cos(next.*omega + phase); -radius * sin(next.*omega + phase)];
        a = mod(angle/180*pi + next.*omega, 2*pi);
        l = wavelength;
        o = order;
        w = width;
        c = color;
        ph = localPhase;
    end

    function loc = getLoc(t)
        loc = [radius(1) * cos(t.*omega(1) + phase(1)); -radius(1) * sin(t.*omega(1) + phase(1))];
    end    
end