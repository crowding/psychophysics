function [strOut] = psychreport(sIn, varargin)
% PSYCHREPORT    text reporting of PFIT results
% 
%   PSYCHREPORT(S), where S is the STRUCT output from PFIT,
%   produces a text report of the results. If an output argument
%   is not requested, then the string is displayed on the terminal.
%   
%   Additional options specify which parts of S should be reported
%   and which not. For example:
%       PSYCHREPORT(S, 'thresholds', '-thresholds.worst', 'stats')
%   produces a report on the thresholds results and statistics, but
%   omits any report of the worst-case limits on thresholds, as
%   contained in S.thresholds.worst.
%   
%   The default options, invoked by the simple PSYCHREPORT(S), are:
%     PSYCHREPORT(S, 'params.est', 'thresholds', 'slopes', 'stats').
%     
%   See also PFIT.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/
	
if isempty(varargin)
	varargin = {'params.est', 'thresholds', 'slopes', 'stats'};
end
varargin = [varargin {'cuts', 'conf', 'R'}];
for i = 1:length(varargin)
	if varargin{i}(1) == '-',
		varargin{i}(1) = [];
		eval(['sIn.' varargin{i} ' = []; s.' varargin{i} ' = [];'], ''); lasterr('')
	else
		eval(['s.' varargin{i} ' = sIn.' varargin{i} ';'], ''); lasterr('')
	end
end

str = ''; nl = sprintf('\n');
str = cat(2, str, ReportPTS(s, 'params', 'parameters'), ReportPTS(s, 'thresholds', 'thresholds'), ReportPTS(s, 'slopes', 'slopes'));
if ~isempty(getf(getf(s, 'params'), 'lims')) | ~isempty(getf(getf(s, 'params'), 'worst')) | ...
	~isempty(getf(getf(s, 'thresholds'), 'lims')) | ~isempty(getf(getf(s, 'thresholds'), 'worst')) | ...
	~isempty(getf(getf(s, 'slopes'), 'lims')) | ~isempty(getf(getf(s, 'slopes'), 'worst'))
		confMethod = getf(sIn, 'confLimMethod'); R = getf(sIn, 'R');
		if ~isempty(confMethod) & ~isempty(R)
			str = cat(2, str, sprintf('%% confidence limits obtained by %s method from %d simulations\n', confMethod, R));
		end
end
if ~isempty(getf(getf(s, 'params'), 'worst')) | ~isempty(getf(getf(s, 'thresholds'), 'worst')) | ~isempty(getf(getf(s, 'slopes'), 'worst'))
	sensMethod = getf(getf(sIn, 'sens'), 'method');
	sensPoints = getf(getf(sIn, 'sens'), 'nPoints');
	sensCvg = getf(getf(sIn, 'sens'), 'coverage');
	if ~isempty(sensMethod) & ~isempty(sensPoints) & ~isempty(sensCvg)
		str = cat(2, str, sprintf('%% worst-case determined by ''%s'' method (%.1f%%, %d points)\n', sensMethod, sensCvg*100, sensPoints));
	end
end
ans = ReportStats(s); if ~isempty(ans), str = cat(2, str, nl, ans); end
if nargout, strOut = str; else disp(str), end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = ReportStats(s)

str = [];
R = getf(s, 'R');
s = getf(s, 'stats');
stats = []; cpes = []; pdpoly = []; kdpoly = []; rhs1 = []; rhs2 = [];
if ~isstruct(s)
	stats = s;
else
	eval('s = s.analysis;', ''); lasterr('')
	stats = [getf(getf(s, 'deviance'), 'D') getf(getf(s, 'pd'), 'corr') getf(getf(s, 'kd'), 'corr')];
	cpes = [getf(getf(s, 'deviance'), 'cpe') getf(getf(s, 'pd'), 'cpe') getf(getf(s, 'kd'), 'cpe')];
	pdpoly = getf(getf(s, 'pd'), 'polyfit');
	kdpoly = getf(getf(s, 'kd'), 'polyfit');
end
if length(stats) ~= 3, return, end
if length(cpes) == 3, stats = [stats; cpes; 1 - cpes]; rhs1 = {'value'}; rhs2 = {'p (left-tailed test)', 'p (right-tailed test)'}; end
head = '% STATISTICS:';
ans = getf(s, 'R'); if ~isempty(ans), R = ans; end
if ~isempty(R) & size(stats, 1) > 1, head = cat(2, head, sprintf(' (based on %d simulations)', R)); end

nl = sprintf('\n');
str = str2mat(MakeTable({'D', 'r_pd', 'r_kd'}, rhs1, [], stats(1, :), '%.4f'), MakeTable([], rhs2, [], stats(2:end, :), '%.3f'));
str = str'; str(end+1, :) = sprintf('\n');
str = cat(2, head, nl, str(:)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = ReportPTS(s, fieldName, name)

str = '';
t = getf(s, fieldName); if isempty(t), return, end
est = getf(t, 'est'); lims = getf(t, 'lims'); worst = getf(t, 'worst');
conf = getf(s, 'conf'); cuts = getf(s, 'cuts'); corner = [];
formats = {'%.4f'}; 
if strcmp(lower(fieldName), 'params')
	cuts = {'alpha', 'beta', 'gamma', 'lambda'};
	formats = {'%.4f', '%.4f', '%.4g', '%.4g'};
end
if ~isempty(est) & (~isempty(lims) | ~isempty(worst))
	for i = 1:length(formats), formats{i} = strrep(formats{i}, '%', '%+'); end
	if ~isempty(lims), lims = lims - repmat(est, size(lims, 1), 1); end
	if ~isempty(worst), worst = worst - repmat(est, size(worst, 1), 1); end
end
conf = repmat(conf(:), ~isempty(lims) + ~isempty(worst), 1);
if ~isempty(lims) | ~isempty(worst), corner = {'conf'}; end
if ~isempty(est), conf = [nan;conf]; end
table = MakeTable(cuts, '%.2g', conf, '%.3f', corner, [est;lims;worst], formats{:});
if isempty(table), return, end
str = table(1, :); table(1, :) = []; estStr = []; limsStr = []; worstStr = [];
if ~isempty(est), str = str2mat(str, strrep(table(1, :), ' +', '  ')); table(1, :) = []; end
if ~isempty(lims), str = str2mat(str, sprintf('%% BOOTSTRAP %s LIMITS:', upper(name(1:end-1))), table(1:size(lims,1), :)); table(1:size(lims,1), :) = []; end
if ~isempty(worst), str = str2mat(str, sprintf('%% WORST-CASE %s LIMITS:', upper(name(1:end-1))), table(1:size(worst,1), :)); table(1:size(worst,1), :) = []; end
nl = sprintf('\n');
str = deblank(str'); str(end+1, :) = nl;
str = strrep(str(:)', '%  NaN', '%  (MLE)');
str = cat(2, sprintf('%% %s:\n', upper(name)), str, nl);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sOut = getf(s, field)

sOut = [];
if nargin < 2
	sOut = s;
elseif length(s)==1 & isstruct(s)
	if isfield(s, field), sOut = getfield(s, field); end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = MakeTable(varargin)

parts = {};
fmt = {};
spacing = 10;
i = 1;
while i <= length(varargin)
	if isstr(varargin{i})
		if strcmp(lower(varargin{i}), 'spacing')
			spacing = varargin{i+1}; i = i + 1;
		else
			fmt{max(length(parts), length(fmt)+1)} = varargin{i};
		end
	else parts{end+1} = varargin{i};
	end
	i = i + 1;
end
if size(parts{end}, 2) > 1, parts = [parts(1:end-1) num2cell(parts{end}, 1)]; end
for i = 1:length(fmt), if isempty(fmt{i}), fmt{i} = '%5g'; end, end
fmt(end+1:3) = {'%5g'};
fmt(end+1:length(parts)) = fmt(end);

for i = 1:length(parts)
	if isempty(parts{i}), parts{i} = {}; end
	parts{i} = parts{i}(:);
	if isnumeric(parts{i})
		if ~any(diff(parts{i})), fmt{i} = strrep(fmt{i}, 'f', 'g'); end
		parts{i} = cellstr(num2str(parts{i}, fmt{i}));
	end
end
parts{1} = parts{1}';
if ~isempty(parts{1}) & ~isempty(parts{2}),
	if isempty(parts{3}), parts{1}(end+1) = {''}; else parts{1}(end+1) = parts{3}; end
end
table = cat(2, parts{4:end});
if isempty(table), str = ''; return, end
if ~isempty(parts{2}), table = cat(2, table, parts{2}); end
if ~isempty(parts{1}), table = cat(1, parts{1}, table); end
for i = 1:size(table, 2)
	column{i} = char(table(:, i));
	if ~isempty(parts{1})
		column{i} = strjust(column{i}, 'center');
		ans = find(any(~isspace(column{i}(2:end, :))));
		column{i}(2:end, min(ans):max(ans)) = strjust(column{i}(2:end, min(ans):max(ans)), 'left');
	end
end
ans = repmat('       %  ', size(column{end}, 1), 1); if ~isempty(parts{1}), ans(min(find(ans=='%'))) = ' '; end
if ~isempty(parts{2}), column{end} = [ans, column{end}]; end
column(2:2:end*2) = column;
for i = 1:2:length(column)
	spaces = 0;
	eval('spaces = spaces + ceil((spacing - size(column{i-1}, 2))/2);', ''); lasterr('')
	eval('spaces = spaces + floor((spacing - size(column{i+1}, 2))/2);', ''); lasterr('')
	column{i} = repmat(' ', size(column{i+1}, 1), max(1, spaces));
end
str = [column{:}];
if ~isempty(parts{1}), str(1) = '%'; end
