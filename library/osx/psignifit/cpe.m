function prob = cpe(vals, distribs)
% CPE      cumulative probability estimate
% 
%   PROB = CPE(VALS, DISTRIBS) Returns cumulative probability estimates
%   for the values VALS, given the distributions in the columns of matrix
%   DISTRIBS. Values in each column of VALS are compared against the
%   corresponding column of DISTRIBS.
%   
%                              #{D_i <= x}
%                   CPE(x; D) = -----------
%                                  R+1
%                 
%     where x is a value from VALS, D is the distribution given by the
%   corresponding column of DISTRIBS, R is the number of elements in D,
%   and # denotes the count of occurences of a condition.
%   
%   If x is a member of D, then the CPE function is the inverse of the
%   QUANTILE function.
% 
%   See also:  QUANTILE

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/

if isempty(vals) | isempty(distribs), prob = []; return, end
if size(vals, 2) ~= size(distribs, 2), error('VALS must have the same number of columns as DISTRIBS'), end

R = size(distribs, 1);
for i = 1:size(vals, 1)
	prob(i, :) = sum(distribs <= repmat(vals(i, :), R, 1)) / (R + 1);
end
