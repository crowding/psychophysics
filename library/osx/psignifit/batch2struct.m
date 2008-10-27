function s = batch2struct(string)
% BATCH2STRUCT    converts from a batch string to a MATLAB struct
% 
%   S = BATCH2STRUCT(B) returns a 1x1 struct.
%   The input is in the "batch string" format required by PSIGNIFIT:
%   keys (which become struct field names) are prefixed with # (each key
%   must also be the first word on the line, not counting whitespace).
%   Values are separated from their keys by whitespace.
% 
%   Batch strings in MATLAB are row vectors, but contain newline characters. 
%   They are therefore suitable for reading from and writing to text files.
%   
%   Output is as a MATLAB struct. Keys must therefore be legal struct
%   field names. Values are converted to numerical scalars or matrices
%   where possible, or otherwise left as strings.
% 
%   Type "help batch_strings" for more information on the batch string format.
% 
%   See also: STRUCT2BATCH, BATCH

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if ~isempty(string) & (~isstr(string) | size(string,1)~=1)
	error('argument should be a one-line string')
end
s = [];
elements = split(string, '#');
for i=1:length(elements)
% 	disp(elements{i}), pause
	[field val] = strtok(elements{i}, [9 10 13 32]);
	val = trytomakenumeric(val);
	if isstr(val)
		val = RemoveTrailingWhiteSpace(val);
		val = fliplr(RemoveTrailingWhiteSpace(fliplr(val)));
	end
	s = setfield(s, lower(field), val);
end

function s = RemoveTrailingWhiteSpace(s)
while 1
	if isempty(s), break, end
	if isempty(findstr(s(end), char([9 10 13 32]))), break, end
	s(end) = [];
end

function c = split(t, varargin)
c = {};
while(~isempty(t))
	[c{length(c)+1} t] = strtok(t, [varargin{:}]);
	if isempty(c{length(c)}) c(length(c)) = []; end
end

function a = trytomakenumeric(a)

% This used to just consist of the eval(...) line below,
% but side effects are a danger if the string happens to
% contain function names. This is just a rough heuristic
% to minimize that risk.
s = lower(a);
s = strrep(s, 'eps', '');
s = strrep(s, 'pi', '');
s = strrep(s, 'nan', '');
s = strrep(s, 'inf', '');
s = strrep(s, 'sqrt', '');
if all(isspace(s) | ismember(s, '0123456789.,;+-*/^()[]e'))
	a = eval(['[' lower(a) ']'], 'a');
	lasterr('');
end
