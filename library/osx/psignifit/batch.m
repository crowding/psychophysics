function opts = batch(varargin)
% BATCH      build, change or examine a batch string
% 
%   The BATCH function can be used to add, remove, change or examine fields
%   B = BATCH(KEY1, VALUE1, KEY2, VALUE2, ......) returns a batch string
%   which records properties according to the specified key/value pairs.
%   Key arguments are strings, and must be legal MATLAB variable names. Values
%   may be strings or numeric matrices.
%     
%   B = BATCH(B, KEY1, VALUE1, KEY2, VALUE2, ......) returns a batch string
%   based on B (B may be empty) with the specified properties added or
%   altered. Properties whose values are set to [] are removed.
%   
%   VALUE = BATCH(B, KEY) returns the value of property specified by KEY, 
%   from the existing batch string B. If B is empty, or does not possess the
%   required property, the function returns [].
% 
%   Type "help batch_strings" for more information on the batch string format.
% 
%   See also BATCH2STRUCT, STRUCT2BATCH

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

opts = [];
if isempty(varargin), return, end
if isstr(varargin{1}) | isempty(varargin{1})
	if any(varargin{1}(:) == '#') | isempty(varargin{1})
		lasterr(''); eval('opts = batch2struct(varargin{1});', ''); error(lasterr)
		varargin(1) = [];
	end
end

if length(varargin) == 1
	if iscell(varargin{1}), varargin = varargin{1}'; end
end
fields = varargin(1:2:end);
values = varargin(2:2:end);

if ~iscellstr(fields), error('key arguments must be strings'), end
if ~isempty(fields), fields = cellstr(lower(char(fields))); end
if length(fields) == 1 & length(values) == 0
	if isempty(opts), return, end
	field = fields{:};
	fields = fieldnames(opts);
	field = strmatch(field, cellstr(lower(char(fields))), 'exact');
	if isempty(field), opts = []; return, end
	opts = getfield(opts, fields{field(1)});
	return
end

if(length(fields) ~= length(values)), error('string arguments must come in key/value pairs'), end
for i=1:length(fields)
	opts = setfield(opts, fields{i}, values{i});
end
opts = struct2batch(opts);
