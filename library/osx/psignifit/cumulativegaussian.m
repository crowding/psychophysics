function y = cumulativegaussian(x, mu, sigma)
% Y = CUMULATIVEGAUSSIAN(X, MU, SIGMA)

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 2, mu = 0; end
if nargin < 3, sigma = 1; end

if length(mu)==1, mu = mu * ones(size(x)); end
if length(sigma)==1, sigma = sigma * ones(size(x)); end

if ~all(size(mu)==size(x)) | ~all(size(sigma)==size(x))
	error('mu and sigma must be scalars, or match the size of x')
end

y = zeros(size(x));
y(find(sigma <= 0)) = nan;
ans = find(sigma > 0);
y(ans) = 0.5 * erfc( (mu(ans) - x(ans)) ./ (sigma(ans) * sqrt(2)));
y(find(y < 0)) = 0;
y(find(y > 1)) = 1;
