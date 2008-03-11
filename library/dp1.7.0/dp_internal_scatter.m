function smat=dp_internal_scatter(mat,parts,dim)
% smat=dp_internal_scatter(mat,parts,dim)
%
% Scatters the variable MAT into PART parts along dimension DIM.
% If DIM is not given, it will be the first non-singleton dimension of MAT.
% SMAT is a one-column cell array containing each part at one cell.

s=size(mat);
if nargin<3 % dim not given
    f=find(s>1);
    if ~isempty(f)
        dim=f(1);
    else
        dim=1;
    end
end
nrows=s(dim);
if nargin<2 % parts not given
    parts=1;
end
    
d=1:ndims(mat);
d(dim)=[];
d=[dim,d];
newmat=permute(mat,d);
ns=size(newmat);

borders=zeros(parts,2);
pos=1;
for i=1:parts
    borders(i,1)=pos;
    if i<=mod(nrows,parts)
        borders(i,2)=pos+fix(nrows/parts);
    else
        borders(i,2)=pos+fix(nrows/parts)-1;
    end
    pos=borders(i,2)+1;
end

smat=cell(parts,1);
for i=1:parts
    if borders(i,1)<=borders(i,2)
        partmat=newmat(borders(i,1):borders(i,2),:);
        ns(1)=borders(i,2)-borders(i,1)+1;
        partmat=reshape(partmat,ns);
        partmat=ipermute(partmat,d);
    else
        partmat=[];
    end
    smat{i}=partmat;
end
