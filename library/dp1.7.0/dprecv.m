function data=dprecv(tid,msgtag)
% data=dprecv(tid,msgtag)
%
% Receives DATA with tag MSGTAG from tasks specified by TID.
%
% TID,MSGTAG must be numeric.
% MSGTAG is optional, default MSGTAG is -1 (receive any tagged message).
% TID is optional, default TID is -1 (receive from any task).
% DATA is a cell array (if TID is a vector) or any MATLAB data type 
% (if TID is scalar).

if nargin<2 || ~isnumeric(msgtag)
    msgtag=-1;
end

if nargin<1 || ~isnumeric(tid)
    tid=-1
end

data=cell(numel(tid),1);
for i=1:numel(tid)
    if numel(tid)==numel(msgtag)
        mt=msgtag(i);
    else
        mt=msgtag(1);
    end
    info=pvm_recv(tid(i),mt);
    if info<0
        error(['Error while calling pvm_recv(',num2str(tid(i)),',',...
            num2str(mt),').']);
    end
    data{i}=dp_internal_unpack;
end

if numel(tid)<=1
    data=data{1};
end