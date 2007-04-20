% R = makecolumn(M)
%
% reshapes M into a column vector.

function R = makecolumn(M);
R = reshape(M, [ prod(size(M)), 1 ] );
