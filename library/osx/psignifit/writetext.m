function fn = writetext(s, fileName, appendflag)
% WRITETEXT     writes a MATLAB string to a text file
% 
%   FILEPATH = WRITETEXT(STRING, FILENAME) Writes a MATLAB string to a
%   text file. The string can be a one row matrix (containing newlines
%   where necessary), or a 2-dimensional character matrix. If it is the
%   latter, then newlines are added, but the trailing blanks on each row
%   are not removed.
% 
%   WRITETEXT(..., '-append') writes to the file in append mode rather
%   than overwriting.
% 
%   If FILENAME is not specified, a standard file dialog is used.
%   If requested, the file path is returned.
% 
%   See also: READTEXT

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 2, fileName = ''; end
if nargin < 3, appendflag = ''; end

if isempty(fileName)
	[a b]=uiputfile('*', 'Save text as:');
	if ~isempty(a) & isstr(a) & isstr(b)
		fileName = fullfile(b, a);
	end
end
if nargout, fn = fileName; end
if isempty(fileName), return, end

if size(s, 1) > 1
	s = [repmat(sprintf('\n'), size(s, 1), 1) s];
	s = s';
	s = s(:);
	s = s';
	s(1) = [];
end

mode = 'wt'; verb = 'save';
if ~isempty(appendflag)
	if isempty(strmatch(lower(appendflag), {'append', '-append'})), error(['unknown command option ''' appendflag '''']), end
	mode = 'at'; verb = 'append to';
end

fid = fopen(fileName, mode);
if fid == -1, error(['could not ' verb ' file ''' fileName '''']), end
fprintf(fid, '%c', s);
if fclose(fid) ~= 0, warning(['unable to close file ''' fileName '''']), end
