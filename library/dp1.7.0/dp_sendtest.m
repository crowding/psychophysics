% dp_sendtest
% tests dpsend/dprecv with several MATLAB data types

i=sqrt(-1);
id=dpmyid;
if id<0
    error('Pvmd not responding, check your PVM system.');
end

d0=rand(5);
dpsend(d0,id,1);
d1=dprecv(id,1);
isequal(d0,d1)

d0=sparse(rand(5));
dpsend(d0,id,2);
d1=dprecv(id,2);
isequal(d0,d1)

d0=rand(5)+i*rand(5);
dpsend(d0,id,3);
d1=dprecv(id,3);
isequal(d0,d1)

d0=sparse(rand(5)+i*rand(5));
dpsend(d0,id,4);
d1=dprecv(id,4);
isequal(d0,d1)

d0=char('Hello World!','Test','blabla');
dpsend(d0,id,5);
d1=dprecv(id,5);
isequal(d0,d1)

d0=logical([1 1 0; 0 0 0]);
dpsend(d0,id,6);
d1=dprecv(id,6);
isequal(d0,d1)

d0={'test',[1 2 3];logical([1;0]),sparse([-19 2 1e-19]);1,0};
dpsend(d0,id,7);
d1=dprecv(id,7);
isequal(d0,d1)

d0=[struct('field1','Hello','field2',[3;2]),...
        struct('field1',sparse(1),'field2',logical([ 0 0 1]))];
dpsend(d0,id,8);
d1=dprecv(id,8);
isequal(d0,d1)

d0=[NaN Inf -Inf];
dpsend(d0,id,9);
d1=dprecv(id,9);
isequalwithequalnans(d0,d1)

