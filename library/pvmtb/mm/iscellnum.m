function tf = iscellnum(s)
%ISCELLNUM True for cell array of numbers.
%   ISCELLSTR(S) returns 1 if S is a cell array of numbers and 0
%   otherwise.  A cell array of numbers is a cell array where 
%   every element is either a numeric value or the empty array [].
%
%   See also ISCELLSTR, ISSTR, CELLSTR, CHAR.

%   Copyright (c) 1984-98 by The MathWorks, Inc.
%   $Revision: 1.10 $  $Date: 1998/12/18 16:28:56 $
%   Tomando como modelo $MATLAB/toolbox/matlab/strfun/iscellstr.m

if isa(s,'cell'),
  res = cellfun('isclass',s,'double');
  tf = all(res(:));
else
  tf = logical(0);
end
