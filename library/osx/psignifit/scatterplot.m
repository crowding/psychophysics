function hOut = scatterplot(x, y, varargin)
% H = SCATTERPLOT(X, Y [, ...])

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 2, y = []; end
if isstr(y), varargin = [{y} varargin]; y = []; end
if isempty(y) & isempty(x), if nargout, hOut = []; end, return, end
if isempty(y)
	if length(x) == prod(size(x)) & size(x, 2) ~= 2
		y = x(:);
		x = (1:length(x))';
		if ishold, x = linspace(min(xlim), max(xlim), length(x))'; end
	else
		if size(x, 2)~=2, error('if only one numeric array is supplied, it must have two columns'), end
		y = x(:, 2);
		x = x(:, 1);
	end
end
lasterr('')
eval('h = plot(x, y, ''marker'', ''o'', ''markersize'', 4, ''linestyle'', ''none'');', '');
error(lasterr)

keys = varargin(1:2:end);
values = varargin(2:2:end);
if length(keys) ~= length(values), error('additional arguments should come in key/value pairs'), end
if ~iscellstr(keys), error('key arguments must be strings'), end
for i =  1:length(keys)
	lasterr('')
	eval('set(h, keys{i}, values{i})', '');
	if ~isempty(lasterr)
		lasterr('')
		if strmatch(lower(keys{i}), {'xlabel', 'ylabel', 'title'}, 'exact')
			eval('set(get(gca, keys{i}), ''string'', values{i})', '');
		else
			eval('set(gca, keys{i}, values{i})', '');
		end
		if ~isempty(lasterr)
			error(['could not set the supplied value for property ''' keys{i}(1,:) ''' of either line or axes'])
		end
	end
end
if ~any(strcmp('markerfacecolor', cellstr(lower(char(keys)))))
	set(h, {'markerfacecolor'}, get(h, {'color'}))
end

x(isinf(x)) = [];
xRange = [min(x) max(x)];
xRange = mean(xRange) + 1.2 * (xRange - mean(xRange));
if ishold, xRange(1) = min(xRange(1), min(xlim)); xRange(2) = max(xRange(2), max(xlim)); end
if diff(xRange) == 0, xRange = xRange + [-1 1]; end
xlim(xRange)

y(isinf(y)) = [];
yRange = [min(y) max(y)];
yRange = mean(yRange) + 1.2 * (yRange - mean(yRange));
if ishold, yRange(1) = min(yRange(1), min(ylim)); yRange(2) = max(yRange(2), max(ylim)); end
if diff(yRange) == 0, yRange = yRange + [-1 1]; end
ylim(yRange)

if nargout, hOut = h; else figure(gcf), end
