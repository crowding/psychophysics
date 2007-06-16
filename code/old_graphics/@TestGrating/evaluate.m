function z = evaluate(b, x, y, t)

%checkerboard pattern, within bounds.
[xi, yi, ti] = extent(b);

xz = (-1) .^ floor(((0:length(x)-1) ./ b.spacing(1))) .* ((x >= xi(1)) & (x < xi(2)));
yz = (-1) .^ floor(((0:length(y)-1) ./ b.spacing(2))) .* ((y >= yi(1)) & (y < yi(2)));
tz = (-1) .^ floor(((0:length(t)-1) ./ b.spacing(3))) .* ((t >= ti(1)) & (t < ti(2)));

%cartesian product of the above
z = reshape(cartprod(cartprod(yz, xz), tz), [length(yz) length(xz) length(tz)]);