function [x, y, t] = sampling(dispatch, this, cal)
% Respect reduced y-sampling of bar stimuli.
[x y0 t] = sampling(dispatch.Patch, this, cal);
[x0 y t0] = sampling(this.primitive, this.primitive, cal);
c = get(this, 'center');
y = y + c(2);

