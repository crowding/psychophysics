function data=dpgather(tid,msgtag,dim)
% data=dpgather(tid,msgtag,dim)
%
% Gathers DATA along dimension DIM with tag MSGTAG from tasks 
% specified by TID.
%
% TID,MSGTAG,DIM must be numeric.
% MSGTAG is optional, default MSGTAG is -1 (receive any tagged message).
% TID is optional, default TID is -1 (receive from any task).
% DIM is optional, default DIM is 1.
% DATA is a MATLAB matrix

if nargin<3 || ~isnumeric(dim)
    dim=1;
end

if nargin<2 || ~isnumeric(msgtag)
    msgtag=-1;
end

if nargin<1 || ~isnumeric(tid)
    tid=-1
end

s_data=dprecv(tid,msgtag);

if numel(tid)>1
    data=dp_internal_gather(s_data,dim);
else
    data=s_data;
end
    