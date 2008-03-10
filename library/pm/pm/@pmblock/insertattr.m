function b = insertattr(b,attr,ind,data);
%INSERTATTR Inserts an attribute of a PMBLOCK for several blocks.
%   B=INSERTATTR(B,ATTR,IND,DATA) Inserts the vector DATA at the index
%   (indices) that follows directly after IND. The following indices will
%   be shifted to the right. The DATA and B must have the same number of
%   rows. ATTR must be one of the following strings:
%    'src', 'dst', 'srcfile', 'dstfile', 'timeout','userdata'
%
%   Examples:
%     a = (1:10)'; b=pmblock(10);
%     b = setattr(b,'userdata',1,a);
%     b.userdata
% 
%     a = createinds(ones(10,10),[10 1]);
%     b = setattr(b,'src',1,a);
%     b.src; ans{:}
%            
%   See also PMBLOCK, GETATTR, DELATTR, SETATTR, GETBLOC, SETBLOC.
  
% Used by PMBLOCK constructor, FUNED.
  
if size(data,1) ~= size(b,1)
  error('length of data does not correspond to number of blocks');
end
w = size(data,2);
% much faster to put 'for loop' inside eval expression
eval(['for n=1:size(data,1),b(n).' attr '(ind+1:end+w)=' ...
      '[data(n,:) b(n).' attr '(ind+1:end)];end']);
