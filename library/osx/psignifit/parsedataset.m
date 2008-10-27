function [x, y, n, r, w, t] = parsedataset(dat, fmt)
% [x, y, n, r, w, t] = PARSEDATASET(DAT, FMT)
% 	FMT may be 'xyn', 'xrn' or 'xrw', or it may be omitted, in which case
% 	an intelligent guess is made based on the content of DAT.

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 2, fmt = []; end
if isempty(dat), x = []; y = []; n = []; r = []; w = []; t = []; return, end

if ~isa(dat, 'double'), error('Data must be a double-precision matrix'), end
if size(dat,2)==4, t = dat(:, 1); dat(:,1) = []; end % remove optional time-stamp column 
if size(dat,2)~=3, error('Data must have three columns'), end

if isempty(fmt)
	fmt = 'xyn';
	if all(dat(:,2) == floor(dat(:,2))) & ~all(dat(:,2) == 1)
		if any(dat(:,2) > dat(:,3))
			fmt = 'xrw';
		else
			fmt = 'xrn';
		end
	end
end
x = dat(: , 1);
r = dat(: , 2);
n = dat(: , 3);
switch fmt
case 'xrn' % do nothing
case 'xyn'
	if any(r > 1), r = r / 100; end
	r = round(r .* n);
case 'xrw'
	n = n + r;
otherwise
	error(sprintf('unrecognized option ''%s''', fmt))
end

if any(n <= 0 | round(n * 10000) ~= 10000 * round(n)), error('numbers of observations (third column) must be positive non-zero whole numbers'), end
y = r ./ n;
w = n - r;
if any(y < 0 | y > 1), error('performance cannot be below 0% or above 100%'), end

if nargout <= 1, x = [x y n]; end
