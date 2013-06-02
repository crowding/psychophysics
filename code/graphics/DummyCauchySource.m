function this = DummyCauchySource(varargin)


%a Cauchy Source produces a list of x, y, angle, wavelength, width, color,
%and phase for each patch to be drawn on the screen.
%
%angles are in radians.
%
%inputs are the timestamp of the next scheduled frame, and the number of
%that frame.
nThings = 100;
speeds = rand(3, nThings)/2 - 0.25; %position; angle; phase
speeds(3,:) = speeds(3,:) * 100; %phasing...
orders = (rand(1, nThings) * 40 + 1);
phases = rand(3, nThings) * 2 * pi;
radii = rand(1, nThings) * 8 + 1;
colors = [0.1;0.1;0.1] * rand(1, nThings) + 0.05;
widths = rand(1, nThings) * 2 + 0.5;

persistent init__;
this = autoobject(varargin{:});

function [xy, angle, wavelength, order, width, color, phase] = get(next, frame)
    xy = [radii; radii] .* [sin(next.*speeds(1,:) * 2 * pi + phases(1,:));cos(next.*speeds(1,:) * 2 * pi + phases(1,:))];
    angle = mod(phases(2,:) + next.*speeds(2,:)*5, 2*pi);
    wavelength = 1 + zeros(1, nThings);
    order = orders;
    width = widths;
    color = colors;
    phase = mod(phases(3,:) + next.*speeds(3,:), 2*pi);
end

end