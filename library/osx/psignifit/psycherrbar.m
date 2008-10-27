function hOut = psycherrbar(observed, lims, levels, varargin)
% PSYCHERRBAR    improved error bar function
% 
%   PSYCHERRBAR(OBS, LIMS, LEVELS, ['h' or 'v'], .....) draws error
%   bars, either horizontally (if 'h' is specified) or vertically ('v').
%   A cross is marked at the observed values OBS, and error bars are
%   drawn across the values in LIMS: each column corresponds to a
%   different error bar and there should be two rows(for a simple
%   error bar) or four rows(for an error bar showing inner and outer
%   ranges). LEVELS specifies the bars horizontal position (for
%   vertical bars) or vertical position (for horizontal bars).
%   Additional arguments specify handle-graphics properties of the
%   LINE objects drawn, such as colour and line style.
%   
%   H = PSYCHERRBAR(....) returns a two-element vector. The first
%   element is a handle to the LINE object marking the crosses
%   at OBS. The second is a handle to the LINE object that forms
%   the error bars.
% 
%   N.B. unlike the MathWorks function, ERRORBAR, PSYCHERRBAR
%   demands that LIMS be specified in absolute coordinates, rather
%   than as offsets relative to OBS. The output structure from PFIT
%   provides limits in the correct format for PSYCHERRBAR.
% 
%   See also PFIT

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/
	
if nargin >= 1
	if isstr(observed)
		if strcmp(lower(observed), 'off') & nargin == 1
			delete(findobj(get(get(0, 'currentfigure'), 'currentaxes'), 'tag', 'psycherrbar_bars'))
			delete(findobj(get(get(0, 'currentfigure'), 'currentaxes'), 'tag', 'psycherrbar_points'))
			return
		end
		if strcmp(lower(observed), 'color') & nargin == 2
			col = lims;
			lasterr('')
			if isstr(col), col = evalin('caller', col, '[]'); end
			error(lasterr)
			h1 = findobj(get(get(0, 'currentfigure'), 'currentaxes'), 'type', 'line', 'tag', 'psycherrbar_bars');
			h2 = findobj(get(get(0, 'currentfigure'), 'currentaxes'), 'type', 'line', 'tag', 'psycherrbar_points');
			eval('set([h1;h2], ''color'', col)', '');
			error(lasterr)
			return
		end		
	end
end

h = [];
orientation = [];
if ~isempty(varargin)
	if isstr(varargin{1})
		orientation = strmatch(lower(varargin{1}), {'horizontal', 'vertical'});
		if ~isempty(orientation), varargin(1) = []; end
	end
end
if isempty(orientation), orientation = 2; end

observed = observed(:);
levels = levels(:);
if length(observed) ~= length(levels), error('LEVELS must have the same number of elements as OBSERVED'), end
if length(observed) ~= size(lims, 2), error('number of columns in LIMS must match the number of elements in OBSERVED'), end

switch size(lims, 1)
case 2
	base = [-1 1 0 0 1 -1]';
	vals = lims([1 1 1 2 2 2], :);
case 4
	base = [-1 1 0 0 [-1 -1 1 1] 0 nan 0 0 1 -1]';
	vals = lims([1 1 1 2 2 3 3 2 2 3 3 4 4 4], :);
otherwise
	return
end

[kk vv lineOpts err] = filteraxesprops(varargin);
error(err)

plotArgs{orientation} = observed;
plotArgs{3 - orientation} = levels;
lasterr(''), eval('h(1) = line(plotArgs{:}, ''tag'', ''psycherrbar_points'', ''marker'', ''x'', lineOpts{:}, ''linestyle'', ''none'');', ''); 
error(lasterr)

axlims = [ylim;xlim]; width = diff(axlims(orientation, :))/100;
base = width * repmat(base, 1, size(vals, 2)) + repmat(levels', size(vals, 1), 1);
base(end+1, :) = nan; vals(end+1, :) = nan;
base = base(:); vals = vals(:);

plotArgs{orientation} = vals;
plotArgs{3 - orientation} = base;
lasterr(''), eval('h(2) = line(plotArgs{:}, ''tag'', ''psycherrbar_bars'', lineOpts{:}, ''marker'', ''none'');', '');
error(lasterr)

figure(gcf)
if nargout, hOut = h(:); end
