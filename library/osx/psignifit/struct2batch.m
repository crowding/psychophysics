function string = struct2batch(s)
% STRUCT2BATCH    converts from a MATLAB struct to a batch string
% 
%   B = STRUCT2BATCH(S) converts the 1x1 struct S into the "batch string"
%   format required by PSIGNIFIT. Keys (struct field names) are prefixed
%   with # on a new line, and values are separated from keys by whitespace.
%   Batch strings in MATLAB are vectors, but contain newline characters. 
%   They are therefore suitable for reading from and writing to text files.
%   
%   e.g.
%       s.shape = 'Weibull';     
%       s.n_intervals = 2;     
%       struct2batch(s)
%     
%     ans = 
%     
%       #shape        Weibull
%       #n_intervals  2
% 
%   Type "help batch_strings" for more information on the batch string format.
% 
%   See also BATCH2STRUCT, BATCH

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 1
%	Test
	s.a = 'Once upon a time...';
	s.b = [0 12 exp(-32.858) -eps nan inf -pi 2/3 exp(32.858)]';
	s.c = -reshape(s.b, 3, 3);
	s.d = str2mat('If I gave my heart to you', 'I''d have none', 'And you''d have two');
	s.e = 1.23e45;
end

nl = sprintf('\n');
tb = sprintf('\t');

vals = {};
empties = [];
if ~isstruct(s) | prod(size(s))~=1, error('input argument must be a 1 x 1 struct'), end
fields = fieldnames(s);
for i = 1:length(fields)
	vals{i} = getfield(s, fields{i});
	if isnumeric(vals{i}), vals{i} = mynum2str(double(vals{i})); end
	if ~isstr(vals{i}), error('all fields must be strings or numeric arrays'), end
	if size(vals{i}, 1) > 1
		vals{i} = cellstr(vals{i})';
		vals{i}(2,:) = {nl};
		vals{i} = cat(2, vals{i}{:});
		vals{i} = vals{i}(1:end-1);
	end
	if ~isempty(findstr(vals{i}, nl)), vals{i} = [nl vals{i} nl]; end
	if isempty(vals{i}), empties = [empties i]; end
end

fields(empties) = [];
vals(empties) = [];
string = [repmat('#', length(fields), 1) lower(char(fields)) repmat(tb, length(fields), 1) char(vals)];
string = [cellstr(string)'; repmat({nl}, 1, length(fields))];
string = string(:);
string = [string{:}];

function str = mynum2str(val)

if isempty(val), str = ''; return, end

ratsn = 32;   %54;
fmt = '%.8g';
nl = sprintf('\n');
tb = sprintf('\t');

if size(val, 2) == 1, val = val.'; end
siz = size(val);
val = val(:);
str = num2str(val, fmt);
str(:,end+1) = tb;
str = cellstr(str(:, [end 1:end-1]));
str(find(val == eps)) = {[tb 'eps']};
str(find(val == -eps)) = {[tb '-eps']};
back = eval(strcat('[', str{:}, ']'))';
bad = find(val ~= back & ~(isnan(val) & isnan(back)));
strbad = {};
for i = 1:length(bad)
	strbad{end+1} = fliplr(deblank(fliplr(deblank(rats(val(bad(i)), ratsn)))));
	if any(strbad{end} == '*'), strbad(end) = []; bad(i) = 0; end
end
if any(bad)
	bad = bad(bad ~= 0);
	strbad = char(strbad);
	strbad(:,end+1) = tb;
	str(bad) = cellstr(strbad(:, [end 1:end-1]));
end
str = reshape(str, siz);
for i = 1:siz(2)
	cols{i} = char(str(:, i));
end

str = cat(2, cols{:})';
str(end+1, :) = nl;
str = str(:)';
str = deblank(str(1:end-1));
if siz(1) > 1, str = strrep(str, tb, '    ');
elseif siz(2) == 1, str(1) = [];
else str([1 end+1]) = '[]'; str = strrep(str, tb, ', ');
end

str = upper(str);
