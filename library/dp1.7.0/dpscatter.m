function dpscatter(data,tid,msgtag,dim)
% dpscatter(data,tid,msgtag,dim)
%
% Scatters DATA along dimension DIM with tag MSGTAG to tasks specified 
% by TID.
%
% DATA can be any Matlab data type.
% TID, MSGTAG,DIM must be numeric.
% MSGTAG is optional, default MSGTAG is 0.
% DIM is optional, default is the first non-singleton dimension of DATA


if nargin<3 || ~isnumeric(msgtag)
    msgtag=0;
end

if ~isnumeric(tid)
    error('TID must be numeric.');
end

parts=numel(tid);
if nargin<4 || ~isnumeric(dim)
    s_data=dp_internal_scatter(data,parts);
else
    s_data=dp_internal_scatter(data,parts,dim(1));
end

for i=1:numel(tid)
    dpsend(s_data{i},tid(i),msgtag(1));
end