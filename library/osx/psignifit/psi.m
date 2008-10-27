function y = psi(shape, params, x)
% PSI    predict performance on a psychophysical task, given a model
% 
%   P = PSI(SHAPE, PARAMS, X) returns probability of a correct (or
%   positive) response as a function of the stimulus variable X:
%   
%       psi = gamma + (1 - gamma - lambda) * F(X, alpha, beta)
%   
%   where each row of the four-column matrix PARAMS specifies
%   a set of parameters alpha, beta, gamma, lambda. The shape of
%   the underlying distribution function F is determined by the
%   string SHAPE: see PSYCHF.
%   
%   Each row of PARAMS is applied to the corresponding row of X,
%   although either one of these arguments may be a one-row vector.
% 
%   See also: PSYCHF, FINDTHRESHOLD, FINDSLOPE

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if isempty(params), y = []; return, end
if size(params, 2)~=4, error('params must have 4 columns'), end
lasterr('')
eval('y = psychf(shape, params(:, 1:2), x);', '');
error(lasterr)
params = params(:, 3:4);

if size(params, 1)==1, params = repmat(params, size(x,1), 1); end
if size(x, 1)==1, x = repmat(x, size(params,1), 1); end
if size(params, 1)~= size(x, 1), error('number of rows in ''params'' and ''x'' must match, unless one of them is a horizontal vector'), end

gamma = repmat(params(:, 1), 1, size(x, 2));
lambda = repmat(params(:, 2), 1, size(x, 2));
clear params

y = gamma + (1 - gamma - lambda).* y;
