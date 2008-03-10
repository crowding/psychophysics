function inds = createinds(data,blocdim)
%Returns strings that can be evaluated with SUBSTRUCT into structures
%that can be used by SUBSREF and SUBASGN. Can be used to create indices
%for PMBLOCKS.
%
%INDS = CREATEINDS(DATA,BLOCDIM)
%   Dimension of output blocks is specified.
%
%INDS = CREATEINDS(DATA,NUM)
%   Number of output blocks is specified. CREATEIND will define the
%   blocksizes.  
%  
%   DATA    can be any matlab matrice, cell or normal.
%   BLOCDIM specifies the dimensions of the blocks according to Matlab
%           standard, all matrices/vectors can be described by an array
%           of at least two elements.
%   NUM     Number of blocks.
%   INDS    a string that can be evaluated as follows into a substruct.
%           
%             s = eval(['subsstruct(' inds{1} ')']) 

  global DEB FIN
  if length(blocdim) == 1 
    % blocdim is number of blocs!
    disp('not implemented... sorry')
    return
  elseif ndims(data) < length(blocdim)
    error('The blocs cannot be of higher dimensions than the input data.')
  end
  
  if ndims(data) > length(blocdim)
    % blocs taken from higher dimension data will automatically have
    % their higher dimension bloc dimensiosn set to one.
    blocdim(end+1:ndims(data)) = ones(ndims(data)-length(blocdim));
  end
  
  numelt = size(data);     % number of elements of data for each dimension
  
  if iscell(data)
    par = '''{}'',{';
  else
    par = '''()'',{';
  end
  DEB = ones(1,length(numelt));
  FIN = zeros(1,length(numelt));
  inds = createind_rec(1,numelt,blocdim);
  for n = 1:length(inds)
    inds{n} = [par inds{n}];
  end
  
function inds = createind_rec(n,numelt,blocdim)
  global DEB FIN
  if n > length(numelt)
    inds = [];
    for m=1:length(numelt)
      if DEB(m) == FIN(m)
	inds = [inds sprintf('%d',DEB(m)) ','];
      else
	inds = [inds  sprintf('%d',DEB(m)) ':' sprintf('%d',FIN(m)) ','];
      end
    end
    inds(end) = '}';
    inds = {inds};
    return
  end
  inds = [];
  DEB(n) = 1; FIN(n) = min(blocdim(n),numelt(n));
  while DEB(n) <= FIN(n)
    inds = [inds ; createind_rec(n+1,numelt,blocdim)];
    DEB(n) = FIN(n)+1; 
    FIN(n) = min(numelt(n),FIN(n)+blocdim(n));
  end
  



