function hOut = plotpf(shape, params, varargin)
% PLOTPF    plots a fitted psychometric function
% 
%   HANDLE = PLOTPF(SHAPE, PARAMS [, ...]) plots the psychometric function(s),
%   whose underlying distribution is determined by the string SHAPE (see
%   PSYCHF for legal values) and whose sets of parameters are given in the
%   rows of the four-column matrix PARAMS (see PSI).
%   
%   Additional arguments are handle graphics arguments which may be used to
%   set the colour, line style, etc of the LINE object in the normal way.
%   AXES object properties may also be specified - where a property has the
%   same name for both LINE and AXES objects, as in the case of 'color', the
%   property is assumed to refer to the LINE. The 'xlim' property behaves
%   exceptionally when the plot is held: in this case the axes limits are not
%   changed, but the line is only plotted between the specified limits.
% 
%   Note that each line of PARAMS is a different set of parameters
%   alpha, beta, gamma, lambda. This allows more than one function to be
%   plotted in the same call. Do not pass an entire set of bootstrap
%   parameters unless you really want to plot several thousand multi-
%   coloured psychometric functions.
% 
%   The function returns a graphics handle to the curve, if requested.
% 
%   See also: PLOTPD, PLOT, PSYCHF

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

yScaling = 1;
if size(params, 2) ~= 4, error('PARAMS must have four columns'), end

wasHeld=ishold;
if ~ishold, cla, end
hold on

old_xLim = get(gca, 'xlim');
old_yLim = get(gca, 'ylim');
[keys, values, lineOpts, err] = filteraxesprops(varargin);
error(err)
xLim = get(gca, 'xlim');
yLim = get(gca, 'ylim');
if ~wasHeld
	if isempty(strmatch('xlim', keys, 'exact'))
		lasterr('')
		eval('xLim = sort(psychf(shape, params(:, 1:2), [0.008, 0.998], ''inverse''));', '');
		error(lasterr)
		xLim = [min(xLim(:,1)) max(xLim(:,2))];
	end
	if isempty(strmatch('ylim', keys, 'exact'))
		yLim = yScaling * [min(params(:,3))-0.05 1.05];
	end
	set(gca, 'xlim', xLim, 'ylim', yLim)
end
x = [min(xLim):(diff(xLim)/500):max(xLim)];
x = repmat(x, size(params, 1), 1);
y = yScaling * psi(shape, params, x);
figure(gcf)
lasterr('')
eval('h = plot(x'', y'', lineOpts{:});', '');
error(lasterr)
if wasHeld
	set(gca, 'xLim', [min([xLim(1) old_xLim(1)]) max([xLim(2) old_xLim(2)])])
	set(gca, 'yLim', [min([yLim(1) old_yLim(1)]) max([yLim(2) old_yLim(2)])])
else
	hold off
end

if nargout, hOut = h; end
