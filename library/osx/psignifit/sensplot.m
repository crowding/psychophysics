function hOut = sensplot(est, sim, sens, lims, hilite)
% HANDLES = SENSPLOT(EST, SIM, SENS, LIMS, HILITE)
% 
% Alternatively, pass a single struct argument with one or more of the
% following fields/subfields:
%     params.est
%     params.sim
%     sens.params
%     params.lims
%     sens.inside
% HANDLES{1} = handle(s) to scatterplots (hilited and not hilited)
% HANDLES{2} = handle to marker for SIM params
% HANDLES{3} = handle to markers for SENS params
% HANDLES{4} = result of PSYCHERRBAR (horizontal)
% HANDLES{5} = result of PSYCHERRBAR (vertical)

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 1, est = []; end
if nargin < 2, sim = []; end
if nargin < 3, sens = []; end
if nargin < 4, lims = []; end
if nargin < 5, hilite = []; end

if isstruct(est)
	s = est;
	est = eval('s.params.est', '[]'); lasterr('')
	if isempty(sim),  sim = eval('s.params.sim', '[]'); lasterr(''), end
	if isempty(sens), sens = eval('s.sens.params', '[]'); lasterr(''), end
	if isempty(lims),  lims = eval('s.params.lims', '[]'); lasterr(''), end
	if isempty(hilite),  hilite = eval('logical(s.sens.inside)', '[]'); lasterr(''), end
end

h = {[], [], [], [], []};

if isempty(hilite)
	hilite = logical(ones(size(sim, 1), 1));
elseif ~islogical(hilite) | prod(size(hilite)) ~= length(hilite) | length(hilite) ~= size(sim, 1)
	error('HILITE must be a logical vector with one element per simulation point')
end	
h{1} = scatterplot(sim(~hilite, 1:2), 'color', [0 0 1]);
hold on
h{1} = [h{1} scatterplot(sim(hilite, 1:2), 'color', [0 0.6 1])];
hold off

if ~isempty(sens)
	[ans i] = sort(angle(sens(:, 1) - mean(sens(:, 1)) + 1i * (sens(:, 2) - mean(sens(:, 2)))));
	h{2} = line(sens(i([1:end 1]), 1), sens(i([1:end 1]), 2), 'marker', '^', 'markersize', 6, 'markerfacecolor', [1 1 0], 'markeredgecolor', [0 0 0], 'linestyle', '-', 'color', [0 0 0], 'linewidth', 1);
	if length(i) > 12, set(h{2}, 'marker', 'none', 'color', [1 1 0], 'linewidth', 2), end
end
if ~isempty(est), h{3} = line(est(1), est(2), 'marker', '^', 'markersize', 12, 'markerfacecolor', [1 0 0], 'markeredgecolor', [0 0 0], 'linewidth', 1); end
set(gca, 'plotboxaspectratio', [1 1 1], 'fontweight', 'bold')
xlabel('\alpha'), ylabel('\beta')

if ~isempty(lims)
	h{4} = psycherrbar(nan, lims(:,1), (min(ylim) + min(sim(:, 2)))/2, 'h', 'color', [0.8 0.4 0], 'marker', 'none');
	h{5} = psycherrbar(nan, lims(:,2), (min(xlim) + min(sim(:, 1)))/2, 'v', 'color', [0.8 0.4 0], 'marker', 'none');
end

if nargout, hOut = h; else figure(gcf), end
