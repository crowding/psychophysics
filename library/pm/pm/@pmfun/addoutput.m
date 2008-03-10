%ADDOUTPUT Adds a output definition to the pmfun
%   F = ADDOUTPUT(F,NAME,DATA) Adds a variable with the name NAME to
%   the output of the function definition F. DATA can be:
%     'SETBLOC'   The data will be stored as a sub-matrix of the output
%                 of the dispatcher. The indices used for this are found
%                 in the F.blocks attribute 'dst'.
%     'SAVEFILE'  The output data will be saved directly by the
%                 slave. The filename of the file to save for each
%                 evalutaion is stored in the  F.blocks as the attribute
%                 'dstfile'.  
%
%   F = ADDOUTPUT(F,NAME,DATA,IND) Does the same as above but allows
%   the user to specify which index of the attribute field that should be
%   used. This is useful if two variables should be saved to the same
%   file. 
%
%   Example:
%      f = pmfun;
%      f = addoutput(f,'result','SETBLOC');
%      f = addoutput(f,'image','SAVEFILE'); 
%      f = addoutput(f,'param','SAVEFILE',1); % save to same file.
%  
%   See also: ADDSPECINPUT, ADDCOMINPUT, DELOUTPUT.

function f = addoutput(f,name,dest,varargin)
  
% decode already existing datain and dataout.
sourcelist = {};
srcindlist = [];
for src=f.datain
  [t, r] = strtok(src{:},'(');
  sourcelist{end+1} = t;
  if isempty(r)
    srcindlist(end+1) = 0;
  else
    srcindlist(end+1) = str2num(r);
  end
end

destlist = {};
dstindlist = [];
for dst=f.dataout
  [t, r] = strtok(dst{:},'(');
  destlist{end+1} = t; 
  dstindlist(end+1) = str2num(r);
end

switch dest
 case 'SETBLOC'
  blk_field = 'dst';
  inds = dstindlist(find(strcmp(dest,destlist)));
 case 'SAVEFILE'
  blk_field = 'dstfile';
  inds = dstindlist(find(strcmp(dest,destlist)));
  inds = [inds srcindlist(find(strcmp('DSTFILE',sourcelist)))];
 otherwise
  error('Not a valid dest. Valid: SETBLOC, SAVEFILE.');
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

if strcmp(dest,'SETBLOC') & blk_index == new
  % new SETBLOC 
  % => increase indices of DST higher than highest_setbloc_ind
  %    shift DST ind > highest_setbloc_ind in pmblock right.
  dst_inds = find(strcmp('DST',sourcelist));
  if ismember(blk_index,srcindlist(dst_inds))
    % the new index did already exist as an DST index
    % => move up the higher DST indices
    higher = find(srcindlist(dst_inds)>=blk_index)
    srcindlist(dst_inds(higher)) = srcindlist(dst_inds(higher))+1
    if ~isempty(f.blocks)
      dst_inds = srcindlist(dst_inds(higher));
      for n=length(dst_inds):-1:1
	f.blocks = setattr(f.blocks,'dst',dst_inds(n), ...
				    getattr(f.blocks,'dst',dst_inds(n)-1));
      end
    end
  end
end

if ~isempty(f.blocks) & blk_index == new
  f.blocks = setattr(f.blocks,blk_field,blk_index,cell(size(f.blocks,1),1));
end
f.dataout{end+1} = [dest '(' int2str(blk_index) ')'];
f.pmrpcfun.argout{end+1} = name;
for n=1:length(sourcelist)
  if srcindlist(n) == 0
    f.datain{n} = sourcelist{n};
  else
    f.datain{n} = [sourcelist{n} '(' int2str(srcindlist(n)) ')'];
  end
end
