function [x, y] = distinctx(x, y)
    oldend = y(end);

    [x, i] = unique(flipud(x(:)));
    y = flipud(y(:))
    y = y(i);
    y(end) = oldend; %for interp
end