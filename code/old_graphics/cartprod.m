function C = cartprod(A, B, sq);
% function C = cartprod(A, B, sq)
%
% Generalized n-dimensional Cartesian product of arrays.
% If A is of dimension (a1, a2. ... an) and B is of dimension (b1, b2 ... bm)
% then the cartesian product of A and B is C, where
% C(x1, ... xn, y1, ... ym) = A(x1, ... xn) B(y1, ... yn).
%
% If sq is set to true, singleton dimensions of C are eliminated as 
% in squeeze().

dims = cat(2, size(A), size(B));
if nargin > 2 && sq
	dims = dims(find(dims > 1));
end
C = reshape(reshape(A, numel(A), 1) * reshape(B, 1, numel(B)), dims);
