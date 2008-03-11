% dp_demo2
% dpspawn, dpsend and dprecv demo
% Slave processes do not terminate.

pid=dpparent;

if pid<0
    error('Pvmd not responding, check your PVM system.');
elseif isempty(pid) % parent task
    tid=dpspawn({'.','.'},'dp_demo2'); % spawn two tasks on local host
    dpsend([1 2 3],tid,1);
    a=dprecv(tid(1),2) % receive from child 1
    b=dprecv(tid(2),2) % receive from child 2
else % child task
    c=dprecv(dpparent,1) % receive from parent task
    dpsend(c,dpparent,2); % send back to parent task
end
    