% R = makerow(M)
%
% reshapes M into a row vector.

function R = makerow(M);
R = reshape(M, [ 1, prod(size(M)) ] );
