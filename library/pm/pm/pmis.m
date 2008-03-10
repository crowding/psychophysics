function info = pmis()
%PMIS Test whether there is an open Parallel Matlab System.
%   INFO=PMIS returns a scalar:
%     1 - PMS open
%     0 - No open PMS.

PM_IS = [];
persistent2('open','PM_IS')
if ~isempty(getenv('PVMEPID')) | ~isempty(PM_IS)
  info = 1;
else
  info = 0;
end



