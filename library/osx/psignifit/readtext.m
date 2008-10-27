function s = readtext(fileName)
% READTEXT     reads the contents of a text file as a MATLAB string
% 
%   STRING = READTEXT(FILENAME) returns a MATLAB string (one row,
%   containing newlines if necessary). If FILENAME is not specified, a
%   standard file dialog is used.
% 
%   See also: WRITETEXT

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

s = [];
if nargin < 1, fileName = ''; end

if isempty(fileName)
	[a b] = uigetfile('*', 'Text file to open:');
	if ~isempty(a) & isstr(a) & isstr(b)
		fileName = fullfile(b, a);
	end
end
if isempty(fileName), return, end

fid = fopen(fileName, 'rt');
if fid == -1, error(['could not open ''' fileName '''']), end
s = fscanf(fid, '%c', inf);
s = char(s(:)');
if fclose(fid) ~= 0, warning(['unable to close file ''' fileName '''']), end
