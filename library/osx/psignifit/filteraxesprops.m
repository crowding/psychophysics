function [keys, values, lineOpts, err] = filteraxesprops(varargin)
% private function for plot functions - makes it easy to write plotting
% functions that allow options like 'title', 'xlim', 'xlabel', etc
% to be passed in on the command line amongst line properties like
% 'markercolor', 'color', 'linestyle', etc.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

args = varargin;
if length(args) == 1, if iscell(args{1}), args = args{1}; end, end
err = '';
lineOpts = {};
values = args(2:2:end)';
keys = args(1:2:end)';
if length(keys) ~= length(values)
	err = 'optional arguments should come in key/value pairs';
elseif ~iscellstr(keys)
	err = 'optional property key arguments must be strings';
else
	if ~isempty(keys), keys = cellstr(lower(char(keys))); end
	h = line(nan, nan);
	for i =  1:length(keys)
		lasterr('')
		eval('set(h, keys{i}, values{i})', '');
		if isempty(lasterr)
			lineOpts(end+1:end+2) = [keys(i) values(i)];
		else
			lasterr('')
			if strmatch(lower(keys{i}), {'xlabel', 'ylabel', 'title'}, 'exact')
				eval('set(get(gca, keys{i}), ''string'', values{i})', '');
			else
				eval('set(gca, keys{i}, values{i})', '');
			end
			if ~isempty(lasterr)
				err = ['could not set the supplied value for property ''' keys{i}(1,:) ''' of either line or axes'];
				break
			end
			lasterr('')
		end
	end
	delete(h)
end
if nargout < 4, error(err), end
