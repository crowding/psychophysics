function y = simulateddata(yGen, n, B)
% y = SIMULATEDDATA(yGen, n, B)

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if nargin < 2, n = 1; end
if nargin < 3, B = size(n, 1); end

if size(yGen, 1) == 1, yGen = repmat(yGen, B, 1); end
if size(yGen, 1) ~= B, error('yGen must have either 1 row or B rows'), end

if size(n, 1) == 1, n = repmat(n, B, 1); end
if size(n, 1) ~= B, error('n must have either 1 row or B rows'), end

if size(n, 2) == 1, n = repmat(n, 1, size(yGen, 2)); end
if size(n, 2) ~= size(yGen, 2), error('n must have the same number of columns as yGen'), end

y = zeros(B, size(yGen, 2));

for i = 1:size(yGen, 2)
	n_i = n(:, i);
	p_i = yGen(:, i);
	
	nCols = max(n_i);
	p_i = repmat(p_i, 1, nCols);
	r = rand(B, nCols);
	r = (r <= p_i);
	clear p_i
	n_i = repmat(n_i, 1, nCols);
	chop = repmat(1:nCols, B, 1);
	chop = chop <= n_i;
	n_i(:, 2:end) = [];
	r = r & chop;
	r = sum(r, 2);
	y(:, i) = r ./ n_i;
end
	
