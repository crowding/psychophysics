function [data,info] = pmget(tid,name)
%PMGET Get a Matlab array from another PMI
%   [DATA,INFO] = PMPUT(TID,NAME) Retrieves the data named NAME from the
%   PM instance TID. This function will always overwrite possible
%   existing variables with the same name. Uses PMEVAL and
%   PMSEND/RECV. If the variable couldn't be found info = -1, otherwise 0
%
%   Note that the target PMI must be in EXTERN mode.
%
%   See also PMEXTERN.
  
if length(tid) > 1
  error('Only one PMI can be specified.');
end
me = sprintf('%d',pvm_mytid);

pmeval(tid,['try, pmsend(' me ',' name ',''' name ''');' ...
	    'catch,pmsend(' me ',{[],-1},''' name ''');end;']);

data = pmrecv(tid,name);
if isequal(data,{[],-1})
  data = [];
  info = -1;
else
  info = 0;
end





