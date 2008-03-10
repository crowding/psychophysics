function b = delattr(b,field,ind);
%DELATTR Deletes an attribute of a PMBLOCK for several blocks.
%   B=DELATTR(B,ATTR,IND) Deletes the values of attribute ATTR index
%   IND from a vector of PMBLOCKS. ATTR has to be one of the following:
%    'src', 'dst', 'srcfile', 'dstfile', 'timeout','userdata'
%
%   See also PMBLOCK, GETATTR, SETATTR.
  
nattr = length(getfield(b(1),field));
nblocks = size(b,1);

% much faster to put 'for loop' inside eval expression
eval(['for n=1:nblocks,b(n).' field '(ind)=[];end']);
