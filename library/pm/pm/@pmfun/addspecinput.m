%ADDSPECINPUT Adds a specific input definition to the pmfun
%   F = ADDSPECINPUT(F,NAME,DATA) Adds a variable with the name NAME to
%   the specific input of the function definition F. DATA can be:
%     'GETBLOC'   The data will come from the input to the dispatcher but
%                 will be indexed to only take a sub-matrix of it for
%                 each evaluation of the function expression. The indices
%                 used are stored in the F.blocks as the attribute 'src'.
%     'LOADFILE'  The data will be loaded directly by the slave. The
%                 filename of the file to load for each evalutaion is
%                 stored in the  F.blocks as the attribute 'srcfile'. 
%     'USERDATA'  The data will come from the 'userdata' field of the
%                 F.blocks, from one block for each evaluation.
%     The following values are also allowed in order to send the contents
%     of a pmblock attribute directly (for debugging/advanced users): 
%     'SRC', 'DST', 'SRCFILE', 'DSTFILE', 'TIMEOUT'.
%
%   F = ADDSPECINPUT(F,NAME,DATA,IND) Does the same as above but allows
%   the user to specify which index of the attribute field that should be
%   used. This is useful if two variables should be loaded from the same
%   file, or if one wants to send along the 'src' attribute together with
%   the data extracted by using it (through 'GETBLOC'). 
%
%   Example:
%      f = pmfun;
%      f = addspecinput(f,'img','GETBLOC');
%      f = addspecinput(f,'ref','LOADFILE'); 
%      f = addspecinput(f,'param','LOADFILE',1); % load from same file.
%  
%   See also: DELSPECINPUT, ADDCOMINPUT, DELCOMINPUT, ADDOUTPUT, DELOUTPUT.

function f = addspecinput(f,name,source,varargin)
 
% decode already existing datain.
sourcelist = {};
indexlist = [];
for src=f.datain
  [t, r] = strtok(src{:},'(');
  sourcelist{end+1} = t;
  if isempty(r)
    indexlist(end+1) = 0;
  else
    indexlist(end+1) = str2num(r);
  end
end

% decode already existing dataout.
destlist = {};
dstindlist = [];
for dst=f.dataout
  [t, r] = strtok(dst{:},'(');
  destlist{end+1} = t; 
  dstindlist(end+1) = str2num(r);
end

switch source
 case {'SRC'}
  inds = indexlist([strmatch('GETBLOC',f.datain); strmatch('SRC(',f.datain)]);
  blockfield = 'src';
 case {'LOADFILE' 'SRCFILE'}
  inds=indexlist([strmatch('LOADFILE',f.datain);strmatch('SRCFILE(',f.datain)]);
  blockfield = 'srcfile';
 case 'GETBLOC'
  inds = indexlist(find(strcmp(source,sourcelist))); 
  blockfield = 'src';
 case {'MARGIN' 'TIMEOUT'}
  % these are not indexed.
  if nargin == 4
    warning([source ' cannot be indexed. Adding non-indexed.']);
  end
  if isempty(f.datain)
    first = 1;
  else
    first = length(f.datain)+1;
  end
  f.datain{first} = source;
  f.pmrpcfun.argin{first} = name;
  return
 case 'DST'
  inds = indexlist(find(strcmp(source,sourcelist)));
  inds = [inds dstindlist(find(strcmp('SETBLOC',destlist)))];
  blockfield = lower(source);  
 case 'DSTFILE'
  inds = indexlist(find(strcmp(source,sourcelist)));
  inds = [inds dstindlist(find(strcmp('SAVEFILE',destlist)))];
  blockfield = lower(source);  
 case 'USERDATA'
  inds = indexlist(find(strcmp(source,sourcelist)));
  blockfield = lower(source);
 otherwise
  error(['Not a valid source. Valid: GETBLOC, LOADFILE, SRC, SRCFILE, DST' ...
	 ' DSTFILE, MARGIN, TIMEOUT, USERDATA.']);
end
inds = unique(inds);
if isempty(inds)
  new = 1;
else
  new = inds(end)+1;
end

if nargin == 4 % the index is specified.
  blk_index = varargin{1};
  if blk_index > new
    error('The given index is to high.');
  end
else
  blk_index = new;  % we have a new index!
end

if strcmp(source,'GETBLOC') & blk_index == new
  % new GETBLOC
  % => We need to update common arguments too.
  %    The GETBLOC must come before the common INPUT or LOAD.
  for common_ind =1:length(f.comdata)
    if ischar(f.comdata{common_ind})
      [data,ind] = strtok(f.comdata{common_ind},'(');
      if any(strcmp(data,{'INPUT','LOAD'}))
	ind = int2str(str2num(ind)+1);
	f.comdata{common_ind} = [data '(' ind ')'];
      end
    end
  end
  src_inds = find(strcmp('SRC',sourcelist));
  if ismember(blk_index,indexlist(src_inds))
    % the new index did already exist as an SRC index
    % => move up the higher SRC indices
    higher = find(indexlist(src_inds)>=blk_index);
    indexlist(src_inds(higher)) = indexlist(src_inds(higher))+1;
    if ~isempty(f.blocks)
      src_inds = indexlist(src_inds(higher));
      for n=length(src_inds):-1:1
	try, 
	  blockdata = getattr(f.blocks,'src',src_inds(n)-1);
	  f.blocks = setattr(f.blocks,'src',src_inds(n),blockdata);
	catch
	end
      end
    end
  end
end

if ~isempty(f.blocks) & blk_index == new
  f.blocks = setattr(f.blocks,blockfield,blk_index,cell(size(f.blocks,1),1));
end

sourcelist{end+1} = source;
indexlist(end+1) = blk_index;
f.pmrpcfun.argin{end+1} = name;
for n=1:length(sourcelist)
  if indexlist(n) == 0
    f.datain{n} = sourcelist{n};
  else
    f.datain{n} = [sourcelist{n} '(' int2str(indexlist(n)) ')'];
  end
end
