function [x, y, z] = sampling(dispatch, this, cal)
% function [x, y, z] = sampling(dispatch, this, cal)
% because the bar is uniform in the Y direction, we can save texture memory and
% compute time by only sampling two Y coordinates for creating a texture.
%
% see @Patch/sampling.m for discussion on the 'dispatch'/'this' arguments.

[x, y, z] = sampling(dispatch.Patch, this, cal);

%sample at the two outermost points that are covered by pixels
pixspac = spacing(cal);

[xi, yi, zi] = extent(this);

miny = pixspac(2) * ceil(yi(1) / pixspac(2));
maxy = pixspac(2) * floor(yi(2) / pixspac(2));
y = [miny maxy];
