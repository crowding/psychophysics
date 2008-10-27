function hOut = psychoplot(varargin)
% H = PSYCHOPLOT([DAT, ] [INFO, ] [plotPropName, plotPropValue, ...])
% 
% INFO can be a cell vector, containing up to 6 arguments in the following order:
%     {SHAPE, PARAMS, TH_EST, TH_LIMS, TH_WORST, LEVELS}
% Arguments may be omitted from the end, or passed as empty: []
% 
% Alternatively, INFO can be a struct, with some or all of the following fields
% and sub-fields:
%     'shape'
%     'params.est'
%     'thresholds.est'
%     'thresholds.lims'
%     'thresholds.worst'
% 
% output argument H, if requested, returns a cell array of graphics handles:
%     H{1} contains handles for the data set (if plotted)
%     H{2} contains a handle for the psychometric function (if plotted)
%     H{3} contains handles for the threshold markers and error bars (if plotted)
%     H{4} contains handles for the "worst case" error bars (if plotted)

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

washeld = ishold;

h = {[], [], [], []};
dat = []; shape = []; params = []; thresholds = []; lims = []; worst = []; levels = [];
datFromStruct = [];
while ~isempty(varargin)
	info = varargin{1};
	switch class(info)
	case 'struct'
		eval('shape = info.shape;', ''); lasterr('')
		eval('params = info.params.est;', ''); lasterr('')
		eval('thresholds = info.thresholds.est;', ''); lasterr('')
		eval('lims = info.thresholds.lims;', ''); lasterr('')
		eval('worst = info.thresholds.worst;', ''); lasterr('')
		eval('datFromStruct = info.dat;', ''); lasterr('')
	case 'cell'
		eval('shape = info{1};', ''); lasterr('')
		eval('params = info{2};', ''); lasterr('')
		eval('thresholds = info{3};', ''); lasterr('')
		eval('lims = info{4};', ''); lasterr('')
		eval('worst = info{5};', ''); lasterr('')
		eval('levels = info{6};', ''); lasterr('')
	case 'double'
		if prod(size(info)) == length(info), levels = info;
		elseif size(info, 2) == 3 | size(info, 2) == 4, dat = info;
		else break
	end
	otherwise
		break
	end
	varargin(1) = [];
end

if isempty(levels) & ~isempty(thresholds) & ~isempty(shape) & ~isempty(params)
	levels = psi(shape, params, thresholds);
end

keys = varargin(1:2:end);
values = varargin(2:2:end);
if length(keys) ~= length(values), error('additional arguments should come in key/value pairs'), end
if ~iscellstr(keys), error('key arguments must be strings'), end

col = [];
ans = max(find(strcmp('color', cellstr(lower(char(keys))))));
if ~isempty(ans), col = values{ans}; keys(ans) = []; values(ans) = []; end

dataRange = [];
if isempty(dat) & ~isempty(datFromStruct), dat = datFromStruct; end
if ~isempty(dat), [x y] = parsedataset(dat); dataRange = [min(x) max(x)]; end

lasterr('')
eval('h = MainPsychoPlot(shape, params, col, washeld, dataRange, dat, thresholds, lims, worst, levels, varargin{:});', '');
if ~washeld, hold off, end
error(lasterr)

if ~isempty(cat(1, h{:})), set(gca, 'tag', 'psychoplot'), end
if nargout, hOut = h; else figure(gcf), end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = MainPsychoPlot(shape, params, col, washeld, dataRange, dat, thresholds, lims, worst, levels, varargin)

h = {[], [], [], []};
if ~isempty(shape) & ~isempty(params)
	col = GetNextItemColor(col, washeld, 'tag', 'psychoplot_function');
	h{2}(1) = plotpf(shape, params, varargin{:}, 'linestyle', '-.', 'marker', 'none', 'tag', 'psychoplot_function', 'color', col);
	hold on
	dataRange = [dataRange; xlim]; dataRange = dataRange(1, :);
	h{2}(2) = plotpf(shape, params, 'linestyle', '-', varargin{:}, 'marker', 'none', 'tag', 'keyed', 'color', col, 'xlim', dataRange);
	h{2} = h{2}(:);
end
if ~isempty(dat)
	col = GetNextItemColor(col, washeld, 'tag', 'psychoplot_dataset');
	h{1} = plotpd(dat, varargin{:}, 'linestyle', 'none', 'color', col);
	set(h{1}(end), 'tag', 'psychoplot_dataset')
	hold on
end
if ~isempty(thresholds) & ~isempty(levels)
	if ~isempty(worst)
		col = GetNextItemColor(col, washeld, 'userdata', 'psychoplot_worst_bar');
		lasterr('')
		eval('ans = get(gca, ''color''); if isstr(ans), get(gcf, ''color''); end', '');
		if isempty(lasterr)
			worstCol = (0.45 * col + 0.55 * ans); worstLineStyle = '-';
		else
			lasterr('')
			worstCol = col; worstLineStyle = '--';
		end
		h{4} = psycherrbar(thresholds, worst, levels - diff(ylim)/100, 'h', varargin{:}, 'linestyle', worstLineStyle, 'marker', 'none', 'markersize', get(0, 'defaultlinemarkersize'), 'color', worstCol, 'userdata', 'psychoplot_worst_bar');
		hold on
	end
	if ~isempty(lims)
		col = GetNextItemColor(col, washeld, 'userdata', 'psychoplot_lims_bar');
		h{3} = psycherrbar(thresholds, lims, levels, 'h', varargin{:}, 'linestyle', '-', 'marker', 'x', 'markersize', get(0, 'defaultlinemarkersize'), 'color', col, 'userdata', 'psychoplot_lims_bar');
		hold on
	end
	if isempty(lims) & isempty(worst)
		col = GetNextItemColor(col, washeld, 'tag', 'psychoplot_threshold_line');
		h{3} = line([1;1]*thresholds, [min(ylim) * ones(size(levels));levels], varargin{:}, 'linestyle', '--', 'marker', 'none', 'color', col, 'tag', 'psychoplot_threshold_line');
		hold on
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function col = GetNextItemColor(col, holdon, varargin)

if isempty(col)
	col = holdon * length(findobj(gca, varargin{:}));
	ans = get(gca, 'colororder'); col = ans(1+rem(col, size(ans, 1)), :);
end
