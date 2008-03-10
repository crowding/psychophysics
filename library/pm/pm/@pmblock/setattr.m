function b = setattr(b,attr,ind,data);
%SETATTR Set an attribute of a PMBLOCK for several blocks.
%   B=SETATTR(B,ATTR,IND,DATA) Sets the values of attribute ATTR index
%   IND to the values from a vector of PMBLOCKS to the values of the
%   vector DATA. The DATA and B must have the same number of rows. ATTR
%   must be one of the following strings:
%    'src', 'dst', 'srcfile', 'dstfile', 'timeout','userdata'
%
%   Examples:
%     a = (1:10)'; b=pmblock(10);
%     b = setattr(b,'userdata',1,a);
%     a2 = getattr(b,'userdata',1) % stored as a cell
%     a3 = [a2{:}]    % recollect into a non-cell vector
% 
%     a = createinds(ones(10,10),[10 1]);
%     b = setattr(b,'src',1,a);
%     getattr(b,'src',1)
%            
%   See also PMBLOCK, GETATTR, DELATTR, INSERTATTR, GETBLOC, SETBLOC.
  
% Used by PMBLOCK constructor, FUNED.
%
% Changes from version 1.00: 
% v1.01 31 March 2001 
%  - setting of normal matrices now possible- always into cell matrices  
  
if size(data,1) ~= size(b,1)
  error('length of data does not correspond to number of blocks');
end

% much faster to put 'for loop' inside eval expression
if iscell(data)
  eval(['for n=1:size(data,1),b(n).' attr '(ind)=[data(n,:)];end']);
else
  eval(['for n=1:size(data,1),b(n).' attr '{ind}=[data(n,:)];end']);
end

