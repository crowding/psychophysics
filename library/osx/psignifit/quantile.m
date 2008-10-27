function q = quantile(d, p, flag)
% QUANTILE    finds the quantiles of a distribution or distributions
% 
%   Q = QUANTILE(D, P), where D and P are vectors, returns the P quantiles
%   of a distribution D.
%   
%   The p quantile of a distribution D is estimated by taking the p(R+1)th
%   ordered value of D, where R is the number of elements in D. If p(R+1) is
%   a whole number, then this is the inverse of the CPE function. Otherwise,
%   QUANTILE linearly interpolates between the two nearest values in the
%   ordered distribution.
%   
%   If D is a matrix, then each column is assumed to be a different
%   distribution. If P has more than one column, then values in each column
%   of P are assumed to refer to the corresponding column of D. If D is a
%   matrix and P a vertical vector, however, then the P quantiles of each
%   distribution are returned in each column of Q.
%     e.g. QUANTILE([D1(:) D2(:)], [p1 p2])
%                returns the p1 quantile of D1 and the p2 quantile of D2.
%             QUANTILE([D1(:) D2(:)], [p1; p2])
%                returns the p1 and p2 quantiles of D1 in the first column,
%                and the p1 and p2 quantiles of D2 in the second column.
% 
%   See also CPE, CONFINT

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/
	
if nargin < 3, flag = []; end
if nargin < 2, p = [0.023; 0.159; 0.841; 0.977]; end

if size(d, 1) == 1, d = d(:); p = p(:); end
if isempty(p) | isempty(d), q = []; return, end
if size(p, 2) == 1, p = repmat(p, 1, size(d, 2)); end
if size(p, 2) ~= size(d, 2), error('if P is a matrix, it must have the same number of columns as D'), end

if ~isreal(d), error('distribution cannot contain complex elements'), end

if isempty(flag)
	d = sort(d);
elseif ~strcmp(lower(flag), 'already sorted')
	error(sprintf('unknown command option ''%s''', flag))
end

if any(p > 1), p = p / 100; end

R = repmat(sum(~isnan(d), 1), size(p, 1), 1);
minP = 1 ./ (R + 1);
maxP = R ./ (R + 1);

outOfBounds = (p < minP | p > maxP);
if any(outOfBounds(:)), warning(sprintf('some quantiles could not be estimated:\nfor a distribution of %d samples, only quantiles from %g to %g can be estimated', min(R(:)), max(minP(:)), min(maxP(:)))), end

p = 1 + (R - 1) .* (p - minP) ./ (maxP - minP);
p(outOfBounds) = 1;
p = p + size(d, 1) * repmat((0:size(d,2)-1), size(p,1), 1); % propagate the necessary index increments column-wise

up = d(ceil(p)); wUp = p - floor(p); wUp(wUp == 0) = 0.5; up = up .* wUp; clear wUp
lo = d(floor(p)); wLo = ceil(p) - p; wLo(wLo == 0) = 0.5; lo = lo .* wLo; clear wLo
q = up + lo;
q(outOfBounds) = NaN;
