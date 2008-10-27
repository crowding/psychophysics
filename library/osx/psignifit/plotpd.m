function hOut = plotpd(dat, varargin)
% PLOTPD    plots psychophysical data
% 
%   HANDLES = PLOTPD(DATA, ....) plots psychophysical data, with the size
%   of each point indicating the number of observations. DATA must be
%   specified as a three-column matrix, using one of the following formats
%   (each row represents one block):
% 
%        xyn format:  stimulus, proportion correct, number of trials
%        xrn format:  stimulus, number correct, number of trials
%        xrw format:  stimulus, number correct, number incorrect
% 
%   (To distinguish between these possibilities, the order of preference
%   is as listed above, but the xyn option is ruled out if all the values
%   in the second column of the DATA matrix are integers, and then the
%   xrn option is ruled out if any values in the second column exceed the
%   corresponding values in the third.  There is potential ambiguity here
%   if xyn format is used with the second column expressed as percentage
%   correct rather than proportion correct. This case should be avoided.)
% 
%   Additional arguments are passed straight into PLOT in order to
%   specify colour, marker, etc.
% 
%   Returns a list of graphics handles - one for each point.
% 
%   See also PLOTPF

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargout, hOut = []; end
if isempty(dat), return, end

numbered = 0; fmt = [];
while isstr(dat) & ~isempty(varargin)
	opt = lower(dat); dat = varargin{1}; varargin(1) = [];
	if strmatch(opt, 'numbered'), numbered = 1; else fmt = opt; end
end

if iscell(dat)
	args = [{[]} varargin]; ind = 1;
	if numbered, args = [{'numbered'} args]; ind = 2; end
	washeld = ishold;
	cols = get(gca, 'colororder'); h = {};
	for i = 1:length(dat)
		args{ind} = dat{i};
		h{i} = plotpd(args{:}); hold on
		col = cols(1+rem(i-1, size(cols, 1)), :);
		set(h{i}, 'color', col, 'markerfacecolor', col, 'markeredgecolor', col)
	end
	if ~washeld, hold off, end
	if nargout, hOut = h; else figure(gcf), end
	return
end

yScaling = 1;
lasterr('')
eval('[x y n] = parsedataset(dat, fmt);', '');
error(lasterr)
y = y * yScaling;

washeld=ishold;
if ~ishold, cla, end
hold on

[keys, values, lineOpts, err] = filteraxesprops(varargin);
error(err)

coefficient = 0.05; exponent = 0.75;
requiredEqualization = 3.65;
h = zeros(size(dat, 1), 1);
for i = size(dat, 1):-1:1
	lasterr('')
	eval('h(i) = line(x(i), y(i), ''marker'', ''o'', lineOpts{:}, ''linestyle'', ''none'');', '');
	error(lasterr)
	marker = get(h(i), 'Marker');
	if strcmp(lower(marker), 'none') marker = 'o'; end
	if strcmp(lower(marker), '.') markerEqualize = requiredEqualization; else markerEqualize = 1; end
	markerSize = get(h(i), 'MarkerSize') * coefficient * n(i)^exponent;
	markerSize = max(markerSize, 2);
	set(h(i), 'MarkerFaceColor', get(h(i), 'Color'))
	if ~isempty(lineOpts), lasterr(''), eval('set(h(i), lineOpts{:})', ''); error(lasterr), end
	set(h(i), 'LineStyle', 'none', 'Marker', marker, 'MarkerSize', markerSize * markerEqualize)
end

xRange = [min(x) max(x)];
xRange = mean(xRange) + 1.25 * (xRange - mean(xRange));
if all(x > 0), xRange(1) = max(xRange(1), 0); end
if all(x < 0), xRange(2) = min(xRange(2), 0); end
if all(x == 0), xRange = [-1 1]; end
if diff(xRange) == 0, xRange = sort([0 2*xRange(1)]); end
yRange = [min(y)-0.05*yScaling 1.05*yScaling];

if washeld
	previousXRange = get(gca, 'xlim');
	previousYRange = get(gca, 'ylim');
	xRange = [min(xRange(1), previousXRange(1)) max(xRange(2), previousXRange(2))];
	yRange = [min(yRange(1), previousYRange(1)) max(yRange(2), previousYRange(2))];
else
	hold off
end

yRange = [min(max(yRange(1), -0.05*yScaling), 0.45 * yScaling) min(yRange(2), 1.05 * yScaling)];
if isempty(strmatch('ylim', keys, 'exact')), set(gca, 'ylim', yRange), end
if diff(xRange) > 0 & isempty(strmatch('xlim', keys, 'exact')), set(gca, 'xlim', xRange), end

if numbered
	for i = length(h):-1:1, set(text(get(h(i), 'xdata') + diff(get(gca, 'xlim'))/50, get(h(i), 'ydata'), num2str(i)), 'color', get(h(i), 'color')); end
end
if nargout, hOut = h;else figure(gcf), end
