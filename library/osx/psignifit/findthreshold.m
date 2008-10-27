function x = findthreshold(shape, params, cuts, option)
% FINDTHRESHOLD    inverse of a psychometric function w.r.t. x
% 
%   X = FINDTHRESHOLD(SHAPE, PARAMS, CUTS) finds the inverse of a
%   psychometric function with respect to the stimulus dimension.
%   
%   With psychophysical performance given by:
%       psi = gamma + (1 - gamma - lambda) * F(x, alpha, beta),
%   the above syntax finds the inverse of F. Alternatively, the
%   syntax X = FINDTHRESHOLD(...., 'performance') finds the inverse
%   of psi.
%   
%   See FINDSLOPE for more details including a description of the
%   arguments.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 4, option = []; end
if nargin < 3, cuts = []; end
if isstr(cuts) & isempty(option), option = cuts; cuts = []; end
if isempty(cuts), cuts = 0.5; end
if isempty(option), option = 'underlying'; end

option = strmatch(lower(option), {'underlying', 'performance'});
if isempty(option), error('unknown command option'), end

if isempty(params), x = []; return, end
if size(params,2) ~= 4 & size(params,2) ~= 2, error('matrix ''params'' must have 2 or 4 columns'), end
if option == 2
	if size(params, 2) ~= 4, error('matrix ''params'' must have 4 columns'), end
	gamma = params(:, 3);
	lambda = params(:, 4);
end
params(:,3:end) = [];
if isempty(cuts), x = []; return, end
if any(cuts(:) > 1), cuts = cuts / 100; end
if any(cuts(:) >= 1 | cuts(:) <= 0), error('''cuts'' must be probabilities greater than 0 and less than 1'), end
if size(params, 1)==1, params = repmat(params, size(cuts, 1), 1); end
if size(cuts, 1)==1, cuts = repmat(cuts, size(params,1), 1); end
if size(params, 1)~= size(cuts, 1), error('number of rows in ''params'' and ''cuts'' must match, unless one of them is a horizontal vector'), end

if option == 2
	gamma = repmat(gamma, size(cuts, 1) / size(gamma, 1), size(cuts, 2));
	lambda = repmat(lambda, size(cuts, 1) / size(lambda, 1), size(cuts, 2));
	[i j] = find(cuts >= 1 - lambda);
	if ~isempty(i)
		warning(sprintf('could not solve for some values (e.g. row %d of params matrix):\ncannot solve for performance levels equal to or greater than 1-lambda', i(1)))
		cuts(sub2ind(size(cuts), i, j)) = NaN;
	end
	[i j] = find(cuts <= gamma);
	if ~isempty(i)
		warning(sprintf('could not solve for some values (e.g. row %d of params matrix):\ncannot solve for performance levels equal to or less than gamma', i(1)))
		cuts(sub2ind(size(cuts), i, j)) = NaN;
	end
	cuts = cuts - gamma;
	gamma = 1 - gamma; gamma = gamma - lambda; clear lambda
	cuts = cuts ./ gamma; clear gamma
end

x = psychf(shape, params, cuts, 'inverse');
