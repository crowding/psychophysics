function [x, y, t] = extent(this);
% function [x, y, t] = extent(this);
% compute the x, y, t bounds of this motion stimulus.
% The ApparemtMotion places the first appearance of an object at its 
% center and successive appearances at the given steps away from it.

primcent = get(this.primitive, 'center');
startloc = makecolumn(primcent);
finishloc = makecolumn(primcent) + [this.dx*(this.n-1); 0; this.dt*(this.n-1)];

start_obj = set(this.primitive, 'center', startloc);
finish_obj = set(this.primitive, 'center', finishloc);

[x1, y1, t1] = extent(start_obj);
[x2, y2, t2] = extent(finish_obj);

bounds1 = [x1;y1;t1]';
bounds2 = [x2;y2;t2]';

bounds = [min(min( bounds1, bounds2 )); max( max(bounds1, bounds2) )]';

%the center of this object offsets the center of the primitives
c = get(this, 'center');
x = bounds(1,:) + c(1);
y = bounds(2,:) + c(2);
t = bounds(3,:) + c(3);
