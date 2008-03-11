% dp_scattertest
% scatter/gather test application
% A random matrix is scattered along three dimensions.

pid=dpparent;

if pid<0
    error('Pvmd not responding, check your PVM system.');
elseif isempty(pid) % parent task
    tid=dpspawn({'.','.','.'},'dp_scattertest'); % spawn tasks on local host

    d0=rand(2,3,4);
    
    dpscatter(d0,tid,0,1);
    d1=dpgather(tid,0,1);
    isequal(d0,d1)
    
    dpscatter(d0,tid,0,2);
    d1=dpgather(tid,0,2);
    isequal(d0,d1)
    
    dpscatter(d0,tid,0,2);
    d1=dpgather(tid,0,2);
    isequal(d0,d1)      
    
else % child tasks
    d=dprecv(dpparent,0)
    dpsend(d,dpparent,0);
    
    d=dprecv(dpparent,0)
    dpsend(d,dpparent,0);
    
    d=dprecv(dpparent,0)
    dpsend(d,dpparent,0);

end
