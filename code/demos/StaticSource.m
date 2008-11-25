function this = StaticSource(varargin)
    persistent init__;
    this = autoobject(varargin{:});

    loc = [];
    angle = [];
    wavelength = 1;
    order = 4;
    width = 1;
    color = [0.5;0.5;0.5];
    phase = 0;

    function [xy_, angle_, wavelength_, order_, width_, color_, phase_] = get(next)
        xy_ = e(loc);
        angle_ = matchcols(angle, xy_);
        wavelength_ = matchcols(wavelength, xy_);
        order_ = matchcols(order, xy_);
        width_ = matchcols(width, xy_);
        color_ = matchcols(color, xy_);
        phase_ = matchcols(phase, xy_);
    end 
end

function out = matchcols(vec, temp)
    if size(vec, 2) == 1
        out = vec(:, ones(1,size(temp,2)));
    else
        out = vec;
    end
end