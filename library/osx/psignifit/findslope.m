function [s, t] = findslope(shape, params, cuts, varargin)
% FINDSLOPE    compute the slope of a psychometric function
% 
%   S = FINDSLOPE(SHAPE, PARAMS, CUTS) finds the derivative of a
%   psychometric function with respect to the stimulus dimension, at
%   a specified level of performance.
%   
%   With psychophysical performance given by:
%       psi = gamma + (1 - gamma - lambda) * F(x, alpha, beta)    (1)
%   this function finds dF/dx at the points at which F == CUTS. 
%     
%   SHAPE is a string specifying the shape of underlying distribution
%   function F: see PSYCHF for the available options. Each row of PARAMS
%   specifies a set of parameters: two columns (alpha and beta) are
%   required. Additional columns for gamma and lambda may be supplied, but
%   the will not be used. CUTS must be expressed as probabilities in the
%   range [0,1], the default being 0.5
%   
%   Note that the above syntax produces output that is independent of
%   gamma and lambda in equation (1). This is because of the assumption
%   that gamma and lambda do not represent factors of psychological
%   interest. An alternative syntax S = FINDSLOPE(..., 'performance')
%   finds d(psi)/dx, at the points at which psi == CUTS.
% 
%   To calculate slopes w.r.t log(x), add another input argument:
%        S = FINDSLOPE(...., 'log')
% 
%   An optional second output argument T contains the threshold - i.e.
%   the value of x at which slope S was evaluated.
%   
%   See also FINDTHRESHOLD

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 3, cuts = []; end
if isstr(cuts), varargin = [{cuts} varargin]; cuts = []; end
if isempty(cuts), cuts = 0.5; end

opts_f = {'underlying', 'performance'};
opts_s = {'linear x', 'log x'};
func_opt = opts_f{1}; slope_opt = opts_s{1};
for i = 1:length(varargin)
	if ~isstr(varargin{i}) | size(varargin{i}, 1) ~= 1, error('unknown command option'), end
	match_f = strmatch(lower(varargin{i}), opts_f);
	if ~isempty(match_f), func_opt = opts_f{match_f(1)}; end
	match_s = strmatch(lower(varargin{i}), opts_s);
	if ~isempty(match_s), slope_opt = opts_s{match_s(1)}; end
	if isempty(match_s) & isempty(match_f), error(sprintf('unknown command option ''%s''', varargin{i})), end
end
if strcmp(lower(shape), 'options'), s = slope_opt; t = func_opt; return, end

if isempty(params), t = []; s = []; return, end
lasterr('')
eval('t = findthreshold(shape, params, cuts, func_opt);', '');
error(lasterr)
s = psychf(shape, params(:,1:2), t, 'derivative');
if strcmp(func_opt, 'performance')
	factor = 1 - params(:, 3) - params(:, 4);
	factor = repmat(factor, size(s, 1) / size(factor, 1), size(s, 2));
	s = s .* factor;
end
if strcmp(slope_opt, 'log x')
	s = log(10) * t .* s;
end
