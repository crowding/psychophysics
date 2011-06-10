function out = caged(xeval, yeval, n, varargin)

ph = linspace(0, 2*pi, n+1);
ph = ph(1:end-1);

ph = bsxfun(@plus, ph, [0; pi/n]);
r = bsxfun(@plus, zeros(1, n), [6;9]);

s = struct...
    ( 'x', bsxfun(@times, r, cos(ph))...
    , 'y', bsxfun(@times, r, sin(ph))...
    , 'orient', ph ...
    , 'semimajor', 0.375 ...
    , varargin{:});

s.orient(5) = s.orient(5) + pi/4;

out = gabor(xeval, yeval, s)*255 + 127.5;
