function x = inversecumulativegaussian(y, mu, sigma)
% X = INVERSECUMULATIVEGAUSSIAN(Y, MU, SIGMA)

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 2, mu = 0; end
if nargin < 3, sigma = 1; end

if length(mu)==1, mu = mu * ones(size(y)); end
if length(sigma)==1, sigma = sigma * ones(size(y)); end

if ~all(size(mu)==size(y)) | ~all(size(sigma)==size(y))
	error('mu and sigma must be scalars, or match the size of y')
end

x = zeros(size(y));
x(find(sigma <= 0 | y < 0 | y > 1)) = nan;
x(find(y == 0)) = -inf;
x(find(y == 1)) = inf;

ans = find(y > 0  &  y < 1 & sigma > 0);
x(ans) = sqrt(2) * sigma(ans) .* erfinv(2 * y(ans) - 1) + mu(ans);
