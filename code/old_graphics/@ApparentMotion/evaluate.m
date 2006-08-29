function z = evaluate(this, x, y, t);
% function z = evaluate(this, x, y, t);
% evaluate the motion stimulus on the given mesh.

z = zeros([length(y) length(x) length(t)]);

%locate the patch
patch = this.primitive;
c = makecolumn(get(patch, 'center'));
offset = get(this, 'center');
x = x - offset(1);
y = y - offset(2);
t = t - offset(3);

for i = 0:(this.n - 1)
	center = c + [this.dx*i 0 this.dt*i]';
	patch = set(patch, 'center', center);
	
	% find the bounds and center of the patch to evaluate
	[xb, yb, tb] = extent(patch);

	%find the right points to evaluate over
	xi = find( (x >= xb(1)) & (x < xb(2)) );
	yi = find( (y >= yb(1)) & (y < yb(2)) );
	ti = find( (t >= tb(1)) & (t < tb(2)) );

	%evaluate within the bounds
	newpatch = evaluate(patch, x(xi), y(yi), t(ti));
	z(yi,xi,ti) = z(yi,xi,ti) + newpatch;
end
