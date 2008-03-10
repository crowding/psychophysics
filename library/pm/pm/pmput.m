function info = pmput(tids,data,name)
%PMPUT Put a Matlab array on other PMI
%   PMPUT(TIDS,DATA,NAME)
%     TIDS specifies the PMI where to put the data.
%     DATA is the actual data to put.
%     NAME is the name under which the data will be stored on the other PMI.
%
%   This function will always overwrite possible existing variables with
%   the same name.
%
%   Note that the target PMI must be in EXTERN mode.
%  
%   See also PMGET, PMEVAL, PMSEND, PMEXTERN.
  
pmsend(tids,data,name);
pmeval(tids,[name '=pmrecv(''' name ''');']);



