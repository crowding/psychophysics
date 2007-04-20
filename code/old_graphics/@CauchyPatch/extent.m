% give useful minimum and maximum values to evaluate the function over.
function [x, y, t] = extent(c);

center = get(c, 'center'); 
sz = c.size;

bounds = [center(:) - [2;1.5;1.5].*sz(:), center(:) + [2;1.5;1.5].*sz(:)];

x = bounds(1,:);
y = bounds(2,:);
t = bounds(3,:);
