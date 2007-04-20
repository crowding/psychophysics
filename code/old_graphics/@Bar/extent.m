function [x, y, t] = extent(this)

center = makecolumn(get(this, 'center'));
sz = makecolumn(this.size);

bounds = [center - sz / 2, center + sz / 2];
x = bounds(1,:);
y = bounds(2,:);
t = bounds(3,:);
