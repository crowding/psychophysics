function this = DummyCauchySource(varargin)

persistent init__;
this = autoobject(varargin{:})


%a Cauchy Source produces a list of x, y, angle, wavelength, width, color,
%and phase for each patch to be drawn on the screen.
%
%inputs are the timestamp of the next scheduled frame, and the number of
%that frame.
function [xy, angle, wavelength, order, width, color, phase] = get(next, frame)
    xy = [sin(next);cos(next)];
    angle = 0;
    wavelength = 1;
    order = 4;
    width = 1;
    color = [1;1;1];
    phase = 0;
end

end