function [x, y, t, xi, yi, ti] = sampling(dispatch, this, cal)
% Respect reduced y-sampling of bar stimuli.
[x y0 t xi yi0 ti] = sampling(dispatch.Patch, this, cal);
[x0 y t0 xi0 yi ti0] = sampling(this.primitive, this.primitive, cal);
c = get(this, 'center');
y = y + c(2);
yi = yi + c(2);
