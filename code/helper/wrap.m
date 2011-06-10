function y = wrap(x, start, length)
%function y = wrap(x, start, length)
%"wraps" a value into the specified interval. Just MOD with an offset.
y = mod(x-start, length) + start;