function mat=dp_internal_gather(smat,dim)
% mat=dp_internal_gather(smat,dim)
%
% Concatenates a cell array SMAT along dimension DIM.
% If DIM is not given, it will be 1.

if nargin<2
    dim=1;
end

if ~isnumeric(smat{1})
    error('dp_internal_gather only gathers numerical cell arrays');
end

parts=numel(smat);
mat=[];
for i=1:parts
    mat=cat(dim,mat,smat{i});
end
