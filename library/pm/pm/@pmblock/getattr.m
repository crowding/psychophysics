%GETATTR Get the attributes of an array of PMBLOCK objects
%   ATTR = GETATTR(B,ATTR) Returns all the values of a specified
%   attribute in a PMBLOCK array. Each line in the returned matrix
%   corresponds to an entry of one PMBLOCK.
%
%   ATTR = GETATTR(B,ATTR,INDEX) Returns only the values from the
%   specified indices of the specified field.
%
%   Example
%      inds = createinds(zeros(1,10),[1 1]);
%      bb = pmblock('src',[inds inds]);
%      attr_both = getattr(bb,'src')
%      attr1 = getattr(bb,'src',1)
%
%   See also: SETATTR, DELATTR, PMBLOCK.

function attr = getattr(b,field,varargin)

error(nargchk(2,3,nargin))

ncol = length(getfield(b(1),field));
nlin = size(b,1);


inds = 1:ncol; % default all columns

if nargin > 2
  inds = varargin{1};
end

eval(['bb = [b.' field '];']);
attr = reshape(bb,ncol,nlin)';
attr = attr(:,inds);