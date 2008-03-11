function dpsend(data,tid,msgtag)
% dpsend(data,tid,msgtag)
%
% Sends DATA with tag MSGTAG to tasks specified by TID.
%
% DATA can be any Matlab data type.
% TID, MSGTAG must be numeric.
% MSGTAG is optional, default MSGTAG is 0.

if nargin<3 || ~isnumeric(msgtag)
    msgtag=0;
end

if ~isnumeric(tid)
    error('TID must be numeric.');
end
    
pvm_initsend(0);
dp_internal_pack(data);
    
for i=1:numel(tid)
    if numel(tid)==numel(msgtag)
        mt=msgtag(i);
    else
        mt=msgtag(1);
    end
    info=pvm_send(tid(i),mt);  
    if info<0
        error(['Error while calling pvm_send(',num2str(tid(i)),',',...
                num2str(mt),').']);
    end
end
