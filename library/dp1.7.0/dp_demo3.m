% dp_demo3
% scatter/gather demo
% Performs a parallel vector multiplication (scalar product).
% Slave processes terminate.

pid=dpparent;

if pid<0
    error('Pvmd not responding, check your PVM system.');
elseif isempty(pid) % parent task
    tid=dpspawn({'.','.'},'dp_demo3'); % spawn two tasks on local host
    a=[1,2,3,4,5]
    b=[5;4;3;2;1]
    dpscatter(a,tid);
    dpscatter(b,tid);
    c=sum(dpgather(tid))
else % child tasks
    a=dprecv(dpparent) % receive partial a from parent task
    b=dprecv(dpparent) % receive partial b from parent task
    c=a*b % calculate c
    dpsend(c,dpparent); % send c back to parent task
    exit; % close MATLAB instance
end
