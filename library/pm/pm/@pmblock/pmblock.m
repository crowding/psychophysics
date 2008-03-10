%PMBLOCK Construct PMBLOCK object
%   PMBLOCK creates a default object
%
%   PMBLOCK(pmblock) creates a copy of the pmblock
%
%   PMBLOCK(n) creates n default PMBLOCKs
%
%   PMBLOCK(Param1,Value1,Param2,Value2,...) creates blocks according to the
%   following possible combinations: 
%
%   Parameter   Allowed values
%    'src'      indices (see createinds) or any data.
%    'dst'      indices (see createinds) or any data.
%    'srcfile'  filenames (see createfnames).
%    'dstfile'  filenames (see createfnames).
%    'timeout'  same as for margin
%    'userdata' column vector of n arbitrary data.
%
%   All values are given in a columb vector. Several values can be given
%   for each parameter, and should then be incapsulated in an array for
%   each block (not cell array). The number of entries for each parameter
%   must be coherent.  
%
%   Examples:
%     inp_inds=createinds(ones(10,10),[1 10]);
%     out_inds=createinds(ones(1, 10),[1 1]);
%     b = pmblock('src',[inp_inds inp_inds],'dst',out_inds,'userdata',(1:10)');
%     b(1), b(2)  % display first two blocks
%
%   See also GETBLOC, SETBLOC, PMFUN, CREATEINDS, CREATEFNAMES.

% v 1.01
% 31 March 2001 
%   Changes made to SETATTR
%   Version information added - version method, version attribute
%   Display modified


function b = pmblock(varargin);

if nargin == 0
  % default values:
  b.src        = {};
  b.dst        = {};
  b.srcfile    = {};
  b.dstfile    = {};
%  b.margin     = 0;
  b.userdata   = {};
  b.timeout    = Inf;
  b.v          = int8(001); % The version number is b.v/100 + 1;
                            % => int8 ok until version 355.
  b = class(b,'pmblock');
elseif nargin==1
  if isa(varargin{1},'pmblock')
    b = varargin{1};
  elseif isa(varargin{1},'double')
    v = version;
    if v(1)==6
      b(varargin{1},1) = pmblock; 
    else
      % un bug sous matlab 5 fait que seuelement la moitie des arguments
      % sont inities avec des valeurs de defaut donnees par le
      % constructeur si la methode ci dessus est utilisee.
      for n=varargin{1}:-1:1,
	b(n,1) = pmblock;
      end
    end
  end
elseif mod(nargin,2) == 0  % nargin >= 2 and even
  data = cell(1,7);
  lens = zeros(1,7);
  for n=1:2:nargin-1,
    switch varargin{n}
     case 'src'
      lens(1) = size(varargin{n+1},1);
      data{1} = varargin{n+1};
     case 'dst'
      lens(2) = size(varargin{n+1},1);
      data{2} = varargin{n+1};
     case 'srcfile'
      lens(3) = size(varargin{n+1},1);
      data{3} = varargin{n+1};
     case 'dstfile'
      lens(4) = size(varargin{n+1},1);
      data{4} = varargin{n+1};
     case 'userdata'
      lens(5) = size(varargin{n+1},1);
      data{5} = varargin{n+1};
%     case 'margin'
%      lens(6) = size(varargin{n+1},1)*size(varargin{n+1},2);
%      data{6} = varargin{n+1};
     case 'timeout'
      lens(6) = size(varargin{n+1},1)*size(varargin{n+1},2);
      data{6} = varargin{n+1};
     otherwise
      error('bad parameter')
    end
  end
  temp = find(lens(1:5)~=0); % indices to initiated values

  % compare these too, if they are assigned and not 1.
  if ~ismember(lens(6),[0 1]) 
    temp = [temp 6];
  end
%  if ~ismember(lens(7),[0 1])
%    temp = [temp 7];
%  end
  if ~all(lens(temp)==lens(temp(1)))
    error(['the different input given do not correspond to the same number' ...
	   ' of blocks.'])'
  end
  % now all data is verified to have the same length.
  l = lens(temp(1));
  b = pmblock(l);
  temp = find(lens~=0); % add even values for margin and timeout
  for n=1:length(temp),
    switch temp(n)
     case 1
      b = setattr(b,'src',[1:size(data{1},2)],data{1});
     case 2
      b = setattr(b,'dst',[1:size(data{2},2)],data{2});
     case 3
      b = setattr(b,'srcfile',[1:size(data{3},2)],data{3});
     case 4
      b = setattr(b,'dstfile',[1:size(data{4},2)],data{4});
     case 5
      b = setattr(b,'userdata',[1:size(data{5},2)],data{5});
     case 6
      if lens(6)==1,
	data{6}= data{6}.*ones(l,1);
      end
      b = setattr(b,'timeout',[1:size(data{6},2)],data{6});
%     case 7
%      if lens(7)==1,
%	data{7}=data{7}.*ones(l,1);
%      end
%      b = setattr(b,'margin',[1:size(data{7},2)],data{7});
    end
  end
else
 error('bad input arguments, verify number and values');
end







