function [sOut, figHandle]= psychostats(dat, p, R, stats, statsSim, sfp, optIn)
% PSYCHOSTATS     assesses goodness-of-fit for models of psychophysical data
%     
%     S = PSYCHOSTATS(DAT, P_MODEL  [, R]) conducts goodness-of-fit tests on the
%     model that predicts probabilities P_MODEL for the experiment that produced
%     binomial data DAT.  DAT must be expressed in the same way as is required 
%     for PSIGNIFIT or PLOTPD: three columns, and one line per data point. 
%     P_MODEL must have one element per data point. R is the number of 
%     replications to be run in the Monte Carlo goodness-of-fit tests. If it is 
%     omitted, or empty, a value of 1999 is assumed.
% 
%     S is a structure that contains the results. It has the following fields:
%         K:        the number of data points
%         N:        the total number of trials
%         R:        number of Monte Carlo runs
%         deviance: struct containing information about the deviance summary
%                   statistic. Contains the following fields:
%                     D:          the value of the deviance statistic
%                     cpe:        the cumulative probability estimate for D,
%                                 based on R Monte Carlo simulations.
%                     residuals:  deviance residuals d.
%         pd:     struct containing information about the relationship between
%                 model prediction p (= P_MODEL) and the deviance residuals d.
%                     corr:       the correlation coefficient between p and d
%                     cpe:        the Monte Carlo cumulative probability
%                                 estimate for the pd correlation coefficient.
%                     polyfit:    struct containing results of polynomial fits
%                                 relating p to d (see below).
%         kd:     struct containing information about the relationship between
%                 deviance residuals d and the order in which they occur in the
%                 data set (denoted by the index vector k). Note that data points
%                 at which the observer performed at 0% or 100% are excluded.
%                 (structure is the same as for pd, above)
%     
%     The 'polyfit' structures summarize the results of least-squares polynomial 
%     fits to the deviance residuals, as a function of either k or p. Each 
%     polynomial fit effectively adds (order+1) extra parameters to the original 
%     model. Fields are as follows:
%        order:  the order of the polynomial fit
%        coeffs: the polynomial coefficients for the best fit (high order first)
%        SSE:     summed squared error of the fit, which is directly comparable
%                 to D because of the use of deviance residuals and the 
%                 "nestedness" of deviance measures.
%        MSE:     = SSE / (K - number of added parameters)
%        chisq:   chi-square values comparing this fit with the original model
%                 (first element of the chisq vector) and subsequent polynomial
%                 fits before this one (in increasing order). The expected drop 
%                 in deviance is distributed according to chi-square with d.f. = 
%                 number of extra parameters, so a significant value here denotes 
%                 a significant improvement in model prediction.
%     
%     PSYCHOSTATS produces graphical output: (1) a plot of the empirical data and 
%     model predictions, with numbers marking the chronological index of each 
%     data point; (2) a plot of deviance residuals against model prediction; (3) 
%     a plot of deviance residuals against chronological indices, with crosses 
%     marking the points discarded in the correlation; (4)-(6) histograms for the 
%     three statistical measures. Each histogram is scaled to have an area of 1, 
%     and is shown along with the empirical value (colour-coded vertical line) 
%     and the boundaries of the 95% confidence interval (red vertical lines). 
%     (Note that the test for deviance is one-sided).
%     
%     S = PSYCHOSTATS(DAT, P_MODEL, R, STATS, SIM_STATS). Without the additional
%     arguments STATS and SIM_STATS, the function will use the PSIGNIFIT engine 
%     to calculate empirical values and generate expected distributions for the 
%     three statistics. However, one may wish to do this in advance (for example, 
%     in order to use  the "refit" option in the engine).  If so, the two final 
%     arguments correspond to the second and fourth output arguments of the 
%     PSIGNIFIT engine: the vector STATS has three elements (deviance,  pd 
%     correlation, kd correlation) and the matrix SIM_STATS has 3 columns 
%     (similarly), and R rows.
			
% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 3, R = []; end
if nargin < 4, stats = []; end
if nargin < 5, statsSim = []; end
if nargin < 6, sfp = []; end
if nargin < 7, optIn = []; end
figHandle = [];

plotpolyfits = 1;
if isempty(optIn)
	plotResults = (nargout == 0);
elseif ~isstr(optIn) | size(optIn, 1) ~= 1, error('unknown comand option (arg #7)')
else
	switch lower(optIn)
		case 'no plot', plotResults = 0;
		case 'plot', plotResults = 1;
		case 'plot with polyfits', plotResults = 1; plotpolyfits = 1;
		case 'plot without polyfits', plotResults = 1; plotpolyfits = 0;
		otherwise, error(sprintf('unknown command option ''%s''', optIn))
	end
end
if ~isempty(statsSim), R = size(statsSim, 1); end
if isempty(R), R = 1999; end

p = p(:);
if ~isreal(p) | any(p > 1 | p < 0), error('P_MODEL must consist of real numbers in the range [0, 1]'), end
if length(p) ~= size(dat, 1), error('number of elements in P_MODEL must match the number of rows in DAT'), end
lasterr(''), eval('[x y n r w] = parsedataset(dat);', ''); error(lasterr)
kdValid = (r > 0 & w > 0);
k = (1:sum(kdValid))';
d = sign(y - p) .* sqrt(2 * (xlogy(r, y) + xlogy(w, 1-y) - xlogy(r, p) - xlogy(w, 1-p)));

if isempty(statsSim)
%	using the psignifit engine
	sfp = 0;
	opts = {
		'gen_values'		p
		'data_y'			y
		'data_n'			n
		'runs'				R
		'compute_params'	0
		'refit'				0
		'verbose'			0
	}';
	ans = cell(1,5); [ans{:}] = psignifit(batch(opts{:}));
	if isempty(stats), stats = ans{2}; end
	statsSim = ans{4};
end


if isempty(stats)
	stats(1) = sum(d.^2);
	ans = corrcoef(p,  d);  stats(2) = ans(2);
	ans = corrcoef(k,  d(kdValid));  stats(3) = ans(2);
end
if isempty(statsSim) % slow script-only version: will not be called if the psignifit engine is running
	sfp = 0;
	yMat = simulateddata(p(:)', n(:)', R);
	statsSim = zeros(R, 3);
	for i = 1:R
		ySim = yMat(i, :)';
		rSim = round(ySim .* n); wSim = n - rSim;
		ySim = rSim ./ n;
	
		dSim = sign(ySim - p) .* sqrt(2 * (xlogy(rSim, ySim) + xlogy(wSim, 1-ySim) - xlogy(rSim, p) - xlogy(wSim, 1-p)));
		statsSim(i, 1) = sum(dSim .^ 2);
		ans = corrcoef(dSim, p); statsSim(i, 2) = ans(2);
		kdValidSim = (rSim > 0 & wSim > 0);
		kSim = (1:sum(kdValidSim))';
		ans = corrcoef(dSim(kdValidSim), kSim); statsSim(i, 3) = ans(2);
	end
end

% cumulative probability estimates
probs = cpe(stats, statsSim);

% polynomial fits of deviance residuals to model prediction or index
deviances = stats(1); extraParams = 0;
maxorder = min(3, length(p)-2);
for order = 0:maxorder
	[pd_polyfit(order+1) deviances extraParams] = fitdevres(p, d, order, deviances, extraParams);
end
if maxorder<1, pd_polyfit = []; end

deviances = stats(1); extraParams = 0;
maxorder = min(3, length(k)-2);
for order = 0:maxorder
	[kd_polyfit(order+1) deviances extraParams] = fitdevres(k, d(kdValid), order, deviances, extraParams);
end
if maxorder<1, kd_polyfit = []; end

% structure output
s.K = length(n);
s.N = sum(n);
s.R = R;
% s.p = p;
% s.n = n;
s.deviance.D = stats(1);
s.deviance.cpe = probs(1);
s.deviance.residuals = d;
s.pd.corr = stats(2);
s.pd.cpe = probs(2);
s.pd.polyfit = pd_polyfit;
s.kd.corr = stats(3);
s.kd.cpe = probs(3);
s.kd.polyfit = kd_polyfit;

% if ~plotResults | nargout > 0, sOut = s; else assignin('caller', 'ans', s); end
sOut = s;
if ~plotResults, return, end


% plot
axOpts = {
	'Box'				'on'
	'DataAspectRatioMode'	'auto'
	'FontSize'			10
	'FontWeight'		'bold'
	'PlotBoxAspectRatio'	[1 1 1]
}';

if isempty(get(0, 'currentfigure')), figure('units', 'normalized', 'position', [0.025, 0.25, 0.95, 0.65]), end
figHandle = gcf;
if ~isempty(get(gcf, 'currentaxes'))
	if strcmp(lower(get(gca, 'buttondownfcn')), 'clickplots(-gca)'), clickplots(-gca), end
end
subplot(2, 3, 1)
if length(d) >= 50
	cla, DoHist(d, [], [], [1 0 0], 'K', 'deviance residuals', 'tag', '', axOpts{:})
	gx = min(xlim):diff(xlim)/200:max(xlim);
	gy = 1/(1.0 * sqrt(2 * pi)) * exp(-((gx - 0.0).^2)/(2 * 1.0^2));
	line(gx, gy / sum(diff(gx) .* (gy(1:end-1) + gy(2:end)) * 0.5), 'linewidth', 2, 'color', [0 1 0])
	ylabel('')
elseif ~strcmp(lower(get(gca, 'tag')), 'psychoplot')
	cla, plotpd('numbered', dat, 'markersize', 4)
	ans = sortrows([dat(:,1), p]); 
	line(ans(:,1), ans(:,2))
	h = findobj(gca, 'type', 'text');
	set(h, 'color', [1 0 0], 'fontweight', 'bold')
	ans = setdiff(get(gca, 'children'), h); set(gca, 'children', [h; ans(:)])
	set(gca,  axOpts{:})
	xlabel('stimulus'); ylabel('performance');
end

subplot(2, 3, 2), cla
plot(p, d, 'o' , 'markeredgecolor', [0 0 0], 'markersize', 7, 'markerfacecolor', [1 0 0]);
modelRange = [0  0.25 0.33 0.5]; modelRange = [modelRange(max(find(min(p) >= modelRange))) 1];
line(modelRange, [0 0], 'color', [0 1 0], 'linewidth', 2)
xlim(modelRange + [-0.05 0.05]), ylim([-1.1 1.1] * max(eps, max(abs(d))))
set(gca,  axOpts{:})
xlabel('model prediction'); ylabel('deviance residuals');
if plotpolyfits % plot polynomial fits
	hold on, base = (min(p):diff([min(p) max(p)])/200:max(p))'; polycolours = get(gca, 'colororder');
	for i = 1:length(s.pd.polyfit), plot(base, polyval(s.pd.polyfit(i).coeffs, base), 'linestyle', '--', 'color', polycolours(1+rem(i-1, size(polycolours, 1)),:)), end
	hold off
end

subplot(2, 3, 3), cla
plot(1:length(d), d, 'o', 'markeredgecolor', [0 0 0], 'markersize', 7, 'markerfacecolor', [1 0 0]);
hold on, plot(find(~kdValid), d(~kdValid), 'x', 'color', [0 0 0], 'markersize', 14), hold off
line([1 length(d)], [0 0], 'color', [0 1 0], 'linewidth', 2)
xlim([0 length(d)+1]), ylim([-1.1 1.1] * max(eps, max(abs(d))))
set(gca,  axOpts{:})
xlabel('index'); ylabel('deviance residuals');
if plotpolyfits % plot polynomial fits
	hold on, base = linspace(1, length(d), 200);
	kbase = base; for i = find(~kdValid(:)'), ans = find(round(base)==i); kbase(ans) = NaN; (max(ans)+1):length(kbase); kbase(ans) = kbase(ans) - 1; end
	for i = 1:length(s.kd.polyfit), plot(base, polyval(s.kd.polyfit(i).coeffs, kbase), 'linestyle', '--', 'color', polycolours(1+rem(i-1, size(polycolours, 1)),:)), end
	hold off
end

subplot(2, 3, 4), cla
DoHist(statsSim(:,1), stats(1), 0.95, [0.2 0.2 1], 'R', 'deviance', axOpts{:})
if ~isempty(sfp), set(chisquareintegral(s.K - sfp), 'color', [0 1 0]), end
title(sprintf('D = %4g:  cpe = %.3g', stats(1),probs(1)));

subplot(2, 3, 5), cla
DoHist(statsSim(:,2), stats(2), [0.025 0.975], [0 0.8 0], 'R', 'model corr. coeff', axOpts{:})
title(sprintf('r = %4g:  cpe = %.3g', stats(2),probs(2)));

subplot(2, 3, 6), cla
DoHist(statsSim(:,3), stats(3), [0.025 0.975], [1 0.8 0], 'R', 'index corr. coeff', axOpts{:})
title(sprintf('r = %4g:  cpe = %.3g', stats(3),probs(3)));

set(gcf, 'paperorientation', 'landscape', 'paperunits', 'normalized', 'paperposition', [0.05 0.05 0.9 0.9])
clickplots('plotboxaspectratio', [1.618 1 1])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUPPORT FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function a = xlogy(x, y)

k = (y==0);
y(k) = nan;
y(x==0 & k) = 1;
a = x.*log(y);
k = isnan(y);
a(k) = -sign(x(k)) * inf;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoHist(distrib, observed, lims, colour, varName, label, varargin)

hold off
distrib = distrib(:);

nBins = min(max(floor(sqrt(length(distrib))), 3), 50);
[n x] = hist(distrib, nBins);
delta = diff(x(1:2));
n = n / (delta * sum(n)); % normalize area
[x y] = stairs(x - delta / 2, n);
x = [x(1); x; [1;1]*(x(end) + delta)];
y = [0; y; y(end); 0];
set(gca, 'ylimmode', 'auto', 'xlimmode', 'auto')
set(fill(x, y, colour / 2), 'edgecolor', colour / 2)
grid on

if ~isempty(observed)
	if observed > max(xlim), xlim(min(xlim) + [0  1.1*(observed - min(xlim))]), end
	if observed < min(xlim), xlim(max(xlim) + [1.1*(observed - max(xlim)) 0]), end
end
if any(distrib < 0) & any(distrib > 0), xlim([-1 1] * max(abs(xlim))), end

set(gca, 'ylimmode', 'manual', 'xlimmode', 'manual')
boundaries = quantile(distrib, lims(:))';
if ~isempty(boundaries), line([1;1] * boundaries, ylim', 'color', [1 0 0], 'linewidth', 1), end
if ~isempty(observed), line([1;1]*observed, ylim', 'color', colour, 'linewidth', 2), end
if ~isempty(varargin), set(gca, varargin{:}), end

if ~isempty(varName), set(text(max(xlim)-diff(xlim)/30, max(ylim)-diff(ylim)/30, sprintf('%s = %d', varName, length(distrib))), 'horizontalAlignment', 'right', 'verticalAlignment', 'top', 'fontsize', get(gca, 'defaulttextfontsize')-1), end
set(gca, 'layer', 'top') % line(xlim, [0 0], 'color', get(gca, 'xcolor'))
xlabel(label)

ans = get(gca, 'title');  set(ans, 'color', get(gca, 'xcolor'))
if ~isempty(observed) & ~isempty(boundaries)
	ans = (observed > boundaries(lims > 0.5)); if isempty(ans), ans = 0; end, panic = mean(ans);
	ans = (observed < boundaries(lims < 0.5)); if isempty(ans), ans = 0; end, panic = max(panic, mean(ans));
	ans = get(gca, 'title');  set(ans, 'color', get(ans, 'color') * (1 - panic) + [1 0 0] * panic)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s, deviances, nParams] = fitdevres(x, y, order, deviances, nParams)

x = x(:);
y = y(:);

n = length(x);
s.order = order;

% Perform a polyfit: suppress warnings completely, but return NaN as
% coefficients if a warning would have been issued. Previous versions
% achieved this by calling POLYFIT with warnings turned off and using
% LASTWARN to detect the warning, but this is not backward-compatible with
% Matlab 5.1 or earlier. The only reasonable solution is now to copy and
% adapt the inner workings of MathWorks' POLYFIT function, with due
% acknowledgment: 
V(:, order+1) = ones(n, 1);
for j = order:-1:1, V(:, j) = x .* V(:, j+1); end
w1 = getwarnstate; warning off
[Q, R] = qr(V, 0);
s.coeffs = [R\(Q'*y)]';
setwarnstate(w1)
if size(R,2) > size(R,1)
	s.coeffs(:) = nan;
elseif condest(R) > 1.0e10
	s.coeffs(:) = nan;
end
%%

prediction = polyval(s.coeffs, x);
s.SSE = sum((prediction - y).^2);
if(n - order - 1 > 0)
	s.MSE = s.SSE / (n - order - 1);
else
	s.MSE = nan;
end

deviances(end+1) = s.SSE;
nParams(end+1) = 1 + order;
for j = 1:length(deviances)-1
	s.chisq(j) = 1 - chisquareintegral(deviances(j) - deviances(end), nParams(end) - nParams(j));
end
