% give useful minimum and maximum values to evaluate the function over.
function [x, y, t] = extent(c);

center = get(c, 'center');

bounds = [makecolumn(center) - [1.2 0.5 1.2]' .* makecolumn(c.size) ...
	  makecolumn(center) + [1.2 0.5 1.2]' .* makecolumn(c.size) ];

x = bounds(1,:); %how does order affect?
y = bounds(2,:);
t = bounds(3,:);
