% dp_demo1
% dpsend and dprecv on one MATLAB instance

id=dpmyid;
if id<0
    error('Pvmd not responding, check your PVM system.');
end

a=[1 2 3]
dpsend(a,id);
b=dprecv(id)
    