function d = readdata(fileName)
% READDATA     reads a numeric matrix from a text file
% 
%   DAT = READDATA(FILENAME) reads a numeric matrix from file FILENAME.
%   Within the file, columns should be delimited by commas, spaces or
%   tabs, and rows should be delimited by newlines or semi-colons
%   (the contents of the file are simply square-bracketed and then run
%   through the MATLAB interpreter).
% 
%   To write a numeric matrix M to a text file, simply use:
%         WRITETEXT(NUM2STR(M))
% 
%   If FILENAME is not specified, a standard file dialog is used.
% 
%   See also READTEXT, WRITETEXT

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 1, fileName = ''; end
lasterr('')
d = eval(['[' readtext(fileName) ']'], '[]');
if ~isempty(lasterr)
	error(['failed to evaluate contents of "' fileName '"'])
end
