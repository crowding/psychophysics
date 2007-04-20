function z = evaluate(b, x, y, t)

[xi, yi, ti] = extent(b);

%boxcar functions along x, y, and z
xz = double( (x >= xi(1)) & (x < xi(2)) );
yz = double( (y >= yi(1)) & (y < yi(2)) );
tz = double( (t >= ti(1)) & (t < ti(2)) );

%cartesian product of the above
z = reshape(cartprod(cartprod(yz, xz), tz), [length(yz) length(xz) length(tz)]);
