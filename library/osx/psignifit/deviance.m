function [D, residuals, p] = deviance(shape, params, x, y, n)
% [D RESIDUALS p] = DEVIANCE(SHAPE, PARAMS, DAT)
% [D RESIDUALS p] = DEVIANCE(SHAPE, PARAMS, x, y, n)
% 
% 	DAT is a standard 3- or 4- column data matrix.
% 	Cases are taken row-by-row: each of the arguments
% 	PARAMS, x, y and n may have a single row, or multiple
% 	rows.
% 
% 	PARAMS should have 4 columns (alpha, beta, gamma, lambda)
% 	except in the special case where SHAPE = 'GEN_VALUES'.
% 	In this case, generating probabilities are supplied
% 	directly in PARAMS, which should have one column per data
% 	point.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin == 3 & ismember(size(x,2), [3 4])
	[x y n] = parsedataset(x);
	x = x'; y = y'; n = n';
elseif nargin < 5
	error('X, Y and N must all be supplied, unless given together in a 3- or 4-column matrix')
end

if any(y(:) < 0 | y(:) > 1), error('Y values must be in the range [0, 1]'), end

if length(n) == 1, n = repmat(n, 1, size(y, 2)); end
if any(diff([size(x, 2) size(y, 2) size(n, 2)]))
	error('X, Y and N must all have the same number of columns (though N may be a scalar)')
end

if size(params, 1) == 1, params = repmat(params, size(y, 1), 1); end
if size(x, 1) == 1, x = repmat(x, size(params, 1), 1); end
if size(y, 1) == 1, y = repmat(y, size(params, 1), 1); end
if size(n, 1) == 1, n = repmat(n, size(params, 1), 1); end
if any(diff([size(x, 1) size(y, 1) size(n, 1) size(params, 1)]))
	error('PARAMS, X, Y and N must all have the same number of rows (except where they are horizontal vectors)')
end

if strcmp(lower(shape), 'gen_values')
	if size(params, 2) ~= size(y, 2), error('number of columns of generating values must match number of data points per set'), end
	if any(params(:) < 0 | params(:) > 1), error('generating values must be in the range [0, 1]'), end
	p = params;
elseif size(params, 2) ~= 4
	error('PARAMS must have 4 columns')
else
	p = psi(shape, params, x);
end

n = round(n);
r = round(n .* y);
w = n - r;
y = r ./ n;

residuals = 2 * (xlogy(r, y) + xlogy(w, 1-y) - xlogy(r, p) - xlogy(w, 1-p));
residuals(residuals < 0) = 0; % can go negative due to precision errors
D = sum(residuals, 2);
if nargout >= 2,
	residuals = sign(y - p) .*sqrt(residuals);
end


function a = xlogy(x, y)

% y(find(x==0 & y==0))=1;
% a = x.*log(y);

k = (y==0);
y(k) = nan;
y(x==0 & k) = 1;
a = x.*log(y);
k = isnan(y);
a(k) = -sign(x(k)) * inf;
