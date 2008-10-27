function hOut = key(varargin)
% KEY    adds a key (otherwise referred to as a legend)
% 
%   HANDLE = KEY(...) creates a floating key or legend similar to MathWorks'
%   LEGEND command. Only LINE objects are listed, and only if they have the
%   word 'keyed' (lower case) in their 'Tag' field.
% 
%   The text labels for the lines come from their 'UserData' property: they are
%   either stored directly as a text string, or, if the label must be stored
%   alongside other user data, 'UserData' can be a one-element struct which has
%   the label string in a field called 'key_label' (lower case). If no label
%   is present, a temporary description is assigned.
% 
%   Labels can be assigned to 'UserData' explicitly if desired (as in the
%   plot commands in the following listing). Alternatively, the KEY command
%   itself can assign the labels, passed in as a list of strings. In the latter
%   case, the key is updated automatically: the former requires a subsequent
%   call to KEY. TeX, strings matrices and strings containing newline characters
%   are all acceptable as labels.
%   
%   Keyed lines are considered grouped if they have the same text label (or
%   if none of them have a label) and they have identical values for 'Color',
%   'LineStyle', 'Marker', 'MarkerFaceColor' and 'MarkerEdgeColor'. Note that
%   variations in line width and and marker size are permitted within a group.
%   A group of lines receives only one entry in the key: they are assumed to
%   represent the same data. To break the grouping, different labels can be
%   assigned to the lines, either directly via their 'UserData', or through
%   the KEY command: the number of string inputs can match either the number
%   of individual keyed lines, or the number of groups.
%   
%   % Example 1:
%     figure
%     plot((1:10).^2, 'Marker', 'square', 'Color', [1 0 0], ...
%            'Tag', 'keyed', 'UserData', 'y = x^2')
%     hold on
%     plot((1:10).^3, 'Marker', 'o', 'Color', [0 0 1], ...
%            'Tag', 'keyed', 'UserData', 'y = x^3')
%     key
%   % subsequent calls can change the labels, e.g. KEY('square', 'cube')
%   % the position of the key, e.g. KEY([0.95 0.25]), or its appearance,
%   % e.g. SET(KEY, 'Visible', 'off') or SET(KEY, 'color', [0.2 0.8 0.8])
%   
%   KEY(AX, ....), where AX is a valid axes handle, attaches the key to those axes.
%   If no lines tagged 'keyed' are present on the axis, no key is created.
%   
%   H = KEY(....) returns a handle to the key: it is a hidden AXES object.
%   Accordingly, all the AXES properties can be set. set(key, 'Visible', 'off'),
%   for example, will remove the box round the key. Some such changes (such as font
%   changes) require an update (call to KEY) before they are seen to take effect.
%   
%   The key can be moved with the mouse by dragging, and updated by clicking.
%   Alternatively, KEY(pos, ...) or KEY(ax, pos, ...), where pos is a two-element
%   vector, specifies the position of the key within the frame of the main axes:
%   x and y coordinates are in normalized units, with 0 causing the key to touch
%   the left or bottom edge of the main axes, and 1 causing it to touch the right
%   or top.
%   
%   KEY OFF or KEY(AX, 'OFF') removes the key attached to AX or the current axes.
%   
%   KEY FRONT or KEY(AX, 'FRONT') brings the key to the front.
%   
%   KEY SPACER or KEY(ax, 'SPACER') makes space in the key by creating an invisible
%   line whose text label consists of spaces. If the functional form is used and an
%   output argument requested, KEY returns the handle to the invisible line in this
%   mode. The gap will not appear until the key is updated. Spacers' labels can be
%   changed, in the normal ways.
%   
%   H = KEY('SPACERS') or H = KEY(ax, 'SPACERS') returns a list of handles to all
%   the spacers on that axis: useful for deleting them if the handles were never
%   recorded.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

spacingConstant = 0.6; lhsPixels = 45;
defaultOptions = {	'xtick', [], 'ytick', [], 'box', 'on', 'visible', 'on', 'fontsize', 10, 'plotboxaspectratiomode', 'auto'};
spacerProps = {'xdata', NaN, 'ydata', NaN, 'linestyle', 'none', 'marker', 'none', 'tag', 'keyed'};

if length(varargin) > 1
	if all(isnan(varargin{1}))
		switch(lower(varargin{2}))
		case 'pickup'
			PickUpAxis
			return
		case 'drag'
			if length(varargin) > 2, DragAxis(varargin{3}), return, end
		case 'drop'
			if length(varargin) > 2, DropAxis(varargin{3}), return, end
			return
		end
	end
end

mainAxis = []; position = [];
for i = 1:2
	if ~isempty(varargin)
		if isnumeric(varargin{1})
			switch prod(size(varargin{1}))
			case 0
				varargin(1) = [];
			case 1
				if ~isempty(mainAxis), error('invalid syntax: more than one scalar argument'), end
				if ~ishandle(varargin{1}), error('scalar argument must be a valid handle'), end
				if ~strcmp(lower(get(varargin{1}, 'type')), 'axes'), error('scalar argument must be a handle to an AXES object'), end
				mainAxis = varargin{1};
				varargin(1) = [];
			case 2
				if ~isempty(position), error('invalid syntax: more than one numeric vector argument'), end
				position = real(double(varargin{1}));
				varargin(1) = [];
			otherwise
				error('invalid syntax: numeric vector argument with more than two elements')
			end
		end
	end
end

if ~iscellstr(varargin), error('non-string arguments are only allowed in the first two positions'), end
if isempty(mainAxis), mainAxis = gca; end

hiddenHandleSetting = get(0, 'showhiddenhandles');
set(0, 'showhiddenhandles', 'on')
allKeys = findobj(get(mainAxis, 'parent'), 'tag', 'key');
existingKey = findobj(get(mainAxis, 'parent'), 'tag', 'key', 'UserData', mainAxis);
set(0, 'showhiddenhandles', hiddenHandleSetting)

if length(varargin) == 1
	switch lower(varargin{1})
	case 'front'
		SendToFront(allKeys)
		varargin = {};
	case 'off'
		delete(existingKey)
		return
	case 'refresh'
		for h = allKeys(:)'
			kf = get(h, 'parent');
			ax = get(h, 'userdata');
			if ~ishandle(ax), ax = get(kf, 'currentaxes'); end % the key has been copied to another figure and its old parent is still recorded, but has been deleted
			af = get(ax, 'parent');
			if kf ~= af  % the key has been copied to another figure and its old parent is still recorded, and still exists
				kfc = findall(kf, 'type', 'axes');
				afc = findall(af, 'type', 'axes');
				ax = kfc(find(afc == ax));
				set(h, 'userdata', ax)
			end
			kcu = get(findall(h), {'userdata'});
			h = key(ax);
			eval('set(findall(h), {''userdata''}, kcu)', '') % try to preserve previous userdata of all the text and line objects in the key
		end
		return
	case 'spacer'
		nSpacers = length(findobj(spacerProps{:}, 'Parent', mainAxis)) + 1;
		h = line(spacerProps{:}, 'Parent', mainAxis, 'userdata', '   ', 'color', 1e-5 * nSpacers * [1 1 1]);
		if nargout, hOut = h; end
		return
	case 'spacers'
		hOut = findobj(spacerProps{:}, 'Parent', mainAxis);
		return
	end
end

[groups names uncollated] = CollateGroups(mainAxis);
if ~isempty(varargin)
	if isempty(names), error('no lines have been tagged ''keyed'''), end
	if length(varargin) == length(groups)
		replace = groups;
	elseif length(varargin) == length(uncollated)
		replace = uncollated;
	else
		error(sprintf('keyed lines: %d;  keyed groups: %d;  => number of string arguments must be either %d or %d', length(uncollated), length(groups), length(uncollated), length(groups)))
	end
	names = varargin(end:-1:1);
	for i = 1:length(replace)
		for j = 1:length(replace{i})
			SetKeyLabel(replace{i}(j), names{i})
		end
	end
end
[groups names] = CollateGroups(mainAxis);
if isempty(groups)
	delete(existingKey)
	return
end
for i = 1:length(groups), groups{i} = groups{i}(1); end
lines = cat(1, groups{:});

if isempty(position)
	position = [0.05 0.5];
	if ~isempty(existingKey)
		set(existingKey, 'units', 'pixels')
		p = (get(existingKey, 'Position') - GetAxesPosition(mainAxis)) .* [1 1 -1 -1];
		position = [p(1)/p(3), p(2)/p(4)];
	end
end
oldAxis = gca;

h = existingKey;
fontProps = {'fontname', 'fontunits', 'fontsize', 'fontweight', 'fontangle'};
if isempty(h), h = axes(defaultOptions{:}); end
if ~ishandle(h), h = axes(defaultOptions{:}); end
set(h, 'units', 'pixels', 'handlevisibility', 'on')
axes(h), cla
y = 0; x = 0;
textHandles = [];
for i = 1:length(lines)
	textHandles(i) = text('string', names{i}, 'units', 'pixels', 'tag', 'keytext');
	extent = get(textHandles(i), 'extent');
	if y==0, y = (1 - spacingConstant) * extent(4); end
	y = y + spacingConstant * extent(4);
	set(textHandles(i), 'position', [lhsPixels y 0], 'horizontalAlignment', 'left', 'verticalAlignment', 'middle', 'fontunits', 'points')
	for j = 1:length(fontProps), set(textHandles(i), fontProps{j}, get(h, fontProps{j})), end
	y = y + spacingConstant * extent(4);
	extent = get(textHandles(i), 'extent');
	x = max([x extent(1)+extent(3)]);
end
y = y + (1 - spacingConstant) * extent(4);
ans = get(h, 'position');
set(h, 'position', [ans(1:2) x + 0.4 * spacingConstant * lhsPixels y])
set(textHandles, 'units', 'data')
coords = get(textHandles, 'position');
if iscell(coords), coords = cat(1, coords{:}); end
x = coords(:, 1);
ans = get(h, 'xlim'); x(:, 2) = ans(1);
midX = mean(x, 2);
x = [midX midX] + (x - [midX midX]) * spacingConstant;
y = coords(:, 2);
set(h, 'xlimmode', 'manual', 'ylimmode', 'manual')
for i = 1:length(lines)
	temp = line(x(i, :), y([i i]), 'marker', 'none', 'tag', 'keyline');
	props = {'color', 'linestyle', 'linewidth'};
	for j = 1:length(props), set(temp, props{j}, get(lines(i), props{j})), end
	temp = line(midX(i), y(i), 'linestyle', 'none', 'tag', 'keymarker');
	props = {'color', 'marker', 'markerfacecolor', 'markeredgecolor', 'markersize'};
	for j = 1:length(props), set(temp, props{j}, get(lines(i), props{j})), end
end	

if ~isempty(position)
	set(h, 'Units', 'pixels')
	pKey = get(h, 'Position');
	pMain = GetAxesPosition(mainAxis);	
	xBounds = [pMain(1), pMain(1) + pMain(3) - pKey(3)];
	yBounds = [pMain(2), pMain(2) + pMain(4) - pKey(4)];
	pKey(1) = xBounds(1) + position(1) * (xBounds(2) - xBounds(1));
	pKey(2) = yBounds(1) + position(2) * (yBounds(2) - yBounds(1));
	set(h, 'Position', pKey)
end
set(h, 'Units', 'normalized', 'DrawMode', 'normal')
set(h, 'Tag', 'key', 'UserData', mainAxis, 'HandleVisibility', 'off')
fig = get(h, 'Parent');
% if isempty(get(fig, 'WindowButtonDownFcn')), set(fig, 'WindowButtonDownFcn', 'key(NaN, ''pickup'')'), end
set([h;get(h, 'children')], 'ButtonDownFcn', 'key(NaN, ''pickup'')')
set(mainAxis, 'DeleteFcn', 'key(gcbo, ''off'')')

set(fig, 'ResizeFcn', '')
axes(oldAxis)
SendToFront([allKeys(:); h])
% set(fig, 'ResizeFcn', 'key refresh')
%% had to comment out line above because of bug (or at least, a highly illogical "feature") in Matlab 6.1.0.450 (and maybe other builds)
%% ... am I alone in getting less and less impressed with the quality of The MathWorks' coding?
if nargout, hOut=h;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SendToFront(handles)

hiddenHandleSetting = get(0, 'showhiddenhandles');
set(0, 'showhiddenhandles', 'on')
for h = handles(:)'
	if ishandle(h)
		p = get(h, 'parent');
		c = get(p, 'children');
		c(find(c == h)) = [];
		c = [h; c];
		set(p, 'children', c)
	end
end
set(0, 'showhiddenhandles', hiddenHandleSetting)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PickUpAxis

hiddenHandleSetting = get(0, 'showhiddenhandles');
set(0, 'showhiddenhandles', 'on')
eligible = findobj(gcf, 'type', 'axes', 'tag', 'key');
set(0, 'showhiddenhandles', hiddenHandleSetting)

if isempty(eligible), return, end
oldFigUnits = get(gcf, 'units');
set(gcf, 'units', 'pixels')
click = get(gcf, 'currentpoint');
set(gcf, 'units', oldFigUnits)
for i = 1:length(eligible)
	h = eligible(1);
	oldAxUnits = get(h, 'units');
	set(h, 'units', 'pixels')
	axPos = get(h, 'position');
	localClick = click - axPos(1:2);
	if all(localClick >= 0 & localClick <= axPos(3:4)), break, end
	set(h, 'units', oldAxUnits)
	eligible(1) = [];
end
if isempty(eligible), return, end
set(h, 'tag', 'moving key', 'handlevisibility', 'on')
set(gcf, 'windowbuttonmotionfcn', ['key(NaN, ''drag'', [' num2str(round(localClick)) '])'])
set(gcf, 'windowbuttonupfcn', ['key(NaN, ''drop'', ''' oldAxUnits ''')'])
set(gcf, 'pointer', 'fleur')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DragAxis(localClick)

oldFigUnits = get(gcf, 'units');
set(gcf, 'units', 'pixels')
pointer = get(gcf, 'currentpoint');
ans = get(gcf, 'position'); bounds = ans(3:4);
set(gcf, 'units', oldFigUnits)


h = findobj(gcf, 'type', 'axes', 'tag', 'moving key');
if isempty(h), set(gcf, 'windowbuttonmotionfcn', '', 'windowbuttonupfcn', ''), return, end
set(h(2:end), 'tag', 'key', 'units', 'normalized', 'drawmode', 'normal', 'handlevisibility', 'off')
h = h(1);
set(h, 'units', 'pixels', 'drawmode', 'fast')
position = [0 0 1 1] .* get(h, 'position') + [pointer 0 0] - [localClick 0 0];
position(1:2)  = max([position(1:2); (-localClick)]);
position(1:2)  = min([position(1:2); (bounds - localClick)]);
set(h, 'position', position)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DropAxis(oldUnits)

set(gcf, 'pointer', 'arrow')
set(gcf, 'windowbuttonmotionfcn', '', 'windowbuttonupfcn', '')
h = findobj(gcf, 'type', 'axes', 'tag', 'moving key');
if isempty(h), return, end
set(h(2:end), 'tag', 'key', 'units', 'normalized', 'drawmode', 'normal', 'handlevisibility', 'off')
h = h(1);
set(h, 'units', oldUnits, 'tag', 'key', 'drawmode', 'normal', 'handlevisibility', 'off')
mainAx = get(h, 'userdata');
if ishandle(mainAx)
	if strcmp(lower(get(mainAx, 'type')), 'axes')
		set(get(mainAx, 'parent'), 'currentaxes', mainAx)
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function name = GetKeyLabel(h)
name = get(h, 'UserData');
if isstruct(name) & prod(size(name)) == 1
	if ~isempty(strmatch('key_label', fieldnames(name), 'exact'))
		name = getfield(name, 'key_label');
	end
end
if ~isstr(name) | isempty(name), name = ''; end
if size(name, 1) > 1
	name = name';
	name = [name; repmat(sprintf('\n'), 1, size(name, 2))];
	name = name(:)';
	name(end) = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetKeyLabel(h, name)
s = get(h, 'UserData');
if isstruct(s) & prod(size(s)) == 1
	s = setfield(s, 'key_label', name);
else
	s = name;
end
set(h, 'UserData', s)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [groups, groupNames, uncollated] = CollateGroups(mainAxis)

lines = findobj(mainAxis, 'type', 'line', 'Tag', 'keyed');
lineNames = cell(length(lines), 1);
groups = {}; groupNames = {}; untitled = 0;
uncollated = num2cell(lines);
for i = 1:length(lines), lineNames{i} = GetKeyLabel(lines(i)); end
while ~isempty(lines)
	name = lineNames{end};
	ind = strmatch(name, lineNames, 'exact');
	if isempty(name), untitled = untitled + 1; name = ['untitled ' num2str(untitled)]; end 
	matchProps = {'marker', 'markerfacecolor', 'markeredgecolor', 'color', 'linestyle'};
	matchProps(2, :) = cell(size(matchProps));
	for j = 1:size(matchProps, 2)
		matchProps{2, j} = get(lines(end), matchProps{1, j});
	end
	groups{end+1} = findobj(lines(ind), matchProps{:});
	groupNames{end+1} = name;
	ind = [];
	for j = 1:size(groups{end})
		ind = [ind; find(lines(:) == groups{end}(j))];
	end
	lines(ind) = []; lineNames(ind) = [];
end
groups = groups(end:-1:1);
groupNames = groupNames(end:-1:1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = GetAxesPosition(h)

oldUnits = get(h, 'units');
set(h, 'units', 'pixels')
p = get(h, 'position');
set(h, 'units', oldUnits)
if strcmp(lower(get(h, 'plotboxaspectratiomode')), 'auto'), return, end
ideal = p(3:4);
r = get(h, 'plotboxaspectratio');
r = r(1) / r(2);
p(3)  = min(p(3), ideal(2) * r);
p(4)  = min(p(4), ideal(1) / r);
p(1:2) = p(1:2) + 0.5 * (ideal - p(3:4));
