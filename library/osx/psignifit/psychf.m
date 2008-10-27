function y = psychf(shape, params, x, mode)
% PSYCHF    distribution underlying psychometric function
% 
%   Y = PSYCHF(SHAPE, PARAMS, X) returns F(X; {alpha, beta}), where F
%   is the monotonic function of X with range [0, 1] that underlies a
%   psychometric function PSI. The shape of F is specified by the string
%   SHAPE, from a choice of: 'Weibull', 'logistic', 'linear',
%   'cumulative Gaussian', 'Gumbel'.
%   
%   PARAMS is a two-column array, each row specifying a given combination
%   of the parameters alpha and beta, where alpha specifies the horizontal
%   position of the curve, and alpha and beta together specify the slope.
%   For X==alpha, F is always independent of beta.
% 
%   The range is 0 to 1 inclusive or exclusive, depending on which function
%   is chosen (the 'linear' function is a straight line with range clipped
%   to [0, 1]).
%   
%   Each row of PARAMS is applied to the corresponding row of X, although
%   either one of these arguments may be a single-row vector.
% 
%   S = PSYCHF(SHAPE, PARAMS, X, 'derivative') evaluates dF/dx at X 
%   X = PSYCHF(SHAPE, PARAMS, Y, 'inverse') evaluates F_inv(Y)
% 
%   See also: PSI

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 4, mode = 'forward'; end

% autocomplete abbreviations
modes = {'forward', 'inverse', 'derivative'};
match = strmatch(lower(mode), modes); if ~isempty(match) & ~isempty(mode), mode = modes{match(1)}; end
shapes = {'Weibull', 'cumulative Gaussian', 'logistic', 'Gumbel', 'linear', 'cg2', 'cg3'};
match = strmatch(lower(shape), cellstr(lower(char(shapes)))); if ~isempty(match) & ~isempty(shape), shape = shapes{match(1)}; end
%%
if nargin < 2, y = shape; return, end
shape = lower(shape);
if isempty(params), y = []; return, end

if size(params, 2)~=2, error('params must have 2 columns'), end
if size(params, 1)==1, params = repmat(params, size(x,1), 1); end
if size(x, 1)==1, x = repmat(x, size(params,1), 1); end
if size(params, 1)~= size(x, 1), error('number of rows in ''params'' and ''x'' must match, unless one of them is a horizontal vector'), end

alpha = repmat(params(:, 1), 1, size(x, 2));
beta = repmat(params(:, 2), 1, size(x, 2));
clear params

if strcmp(lower(shape), 'weibull')
	[i j] = find(alpha <= 0 | beta <= 0);
	if ~isempty(i)
		warning(sprintf('Weibull function cannot take alpha<=0 or beta<=0 (eg row %d of params matrix)', i(1)))
		x(i,:) = NaN;
	end
	[i j] = find(x < 0);
	if ~isempty(i)
		warning('Weibull function cannot take x<0')
		x(i + (j - 1) * size(x, 1)) = NaN;
	end
end
if strcmp(lower(mode), 'inverse')
	[i j] = find(x <= 0 | x >=1);
	if ~isempty(i)
		warning('illegal attempt to solve inverse psychometric probability distribution for p<=0 or p>=1')
		x(i + (j - 1) * size(x, 1)) = NaN;
	end
end
y = 'nothing';
switch lower(shape)
case 'weibull'
	switch lower(mode)
	case 'forward'
		y = 1 - exp(-(x ./ alpha) .^ beta);
	case 'inverse'
		y = alpha .* (-log(1 - x)) .^ (1 ./ beta);
		y(find(y <= 0)) = NaN;
	case 'derivative'
		y = beta ./ alpha .* (x ./ alpha).^(beta - 1) .* exp(-(x ./ alpha).^beta);
	end
case 'logistic'
	switch lower(mode)
	case 'forward'
		y = 1 ./ (1 + exp((alpha - x) ./ beta));
	case 'inverse'
		y = alpha - beta .* log(1 ./ x - 1);
	case 'derivative'
		y = exp((alpha - x) ./ beta) ./ (beta .* (1 + exp((alpha - x) ./ beta)).^2);
	end
case 'linear'
	switch lower(mode)
	case 'forward'
		alpha = 0.5 - alpha .* beta;
		y = x .* beta + alpha;
		y = y .* (y<=1 & y>=0) + (y>1);
	case 'inverse'
		y = alpha + (x - 0.5) ./ beta;
	case 'derivative'
		alpha = 0.5 - alpha .* beta;
		y = x .* beta + alpha;
		f = find(y <= 0 | y >= 1);
		y = beta;
		y(f) = 0;
	end
case 'gumbel'
	switch lower(mode)
	case 'forward'
		y = 1 - exp(-exp((x - alpha) ./ beta));
	case 'inverse'
		y = alpha + beta .* log(-log(1 - x));
	case 'derivative'
		y = exp((x - alpha) ./ beta - exp((x - alpha) ./ beta)) ./ beta;
	end
case 'cumulative gaussian'
	switch lower(mode)
	case 'forward'
		b1 = .31938153;
		b2 = -.356563782;
		b3 = 1.781477937;
		b4 = -1.821255978;
		b5 = 1.330274429;
		z = (x - alpha) ./ beta;
		p = 1 ./ (1 + 0.2316419 * abs(z));
		y = exp(-0.5 * z.^2) / sqrt(2 * pi) .* (b1*p + b2*p.^2 + b3*p.^3 + b4*p.^4 + b5*p.^5);
		y(z > 0) = 1 - y(z > 0);
	case 'inverse'
		y = x;
		x = x * 2 - 1;
		k = find(abs(x) > 0.7);
		if ~isempty(k)
			z = sqrt(-log((1 - abs(x(k))) / 2));
			temp1 = repmat(1.641345311, size(z));
			temp1 = temp1 .* z + 3.429567803;
			temp1 = temp1 .* z - 1.624906493;
			temp1 = temp1 .* z - 1.970840454;
			temp2 = repmat(1.637067800, size(z));
			temp2 = temp2 .* z + 3.543889200;
			temp2 = temp2 .* z + 1.0;
			y(k) = temp1 ./ temp2 .* sign(x(k));
		end
		k = find(abs(x) <= 0.7);
		if ~isempty(k)
			z = x(k).^2;
			temp1 = repmat(-0.140543331, size(z));
			temp1 = temp1 .* z + 0.914624893;
			temp1 = temp1 .* z - 1.645349621;
			temp1 = temp1 .* z + 0.886226899;
			temp2 = repmat(0.012229801, size(z));
			temp2 = temp2 .* z - 0.329097515;
			temp2 = temp2 .* z + 1.442710462;
			temp2 = temp2 .* z - 2.118377725;
			temp2 = temp2 .* z + 1.0;
			y(k) = x(k) .* temp1 ./ temp2;
		end
		y = sqrt(2) * beta .* y + alpha;
	case 'derivative'
		y = exp(-0.5 * ((x - alpha) ./ beta).^2) ./ (beta * sqrt(2.0 * pi));
	end
case 'cg2'
	switch lower(mode)
	case 'forward'
		y = beta .* x - alpha;
		y = 0.5 * erfc(-y / sqrt(2));
	case 'inverse'
		y = erfinv(2 * x - 1) * sqrt(2);
		y = (y + alpha) ./ beta;
	case 'derivative'
		y = beta .* exp(-0.5 * (beta .* x - alpha).^2) ./ sqrt(2.0 * pi);
	end
case 'cg3'
	switch lower(mode)
	case 'forward'
		y = beta .* (x - alpha);
		y = 0.5 * erfc(-y / sqrt(2));
	case 'inverse'
		y = erfinv(2 * x - 1) * sqrt(2);
		y = y ./ beta + alpha;
	case 'derivative'
		y = beta .* exp(-0.5 * (beta .* (x - alpha)).^2) ./ sqrt(2.0 * pi);
	end
otherwise
	error(['unknown psychometric function ''' shape ''''])
end
if isstr(y), error(['unknown command option ''' mode '''']), end
y = real(y);
