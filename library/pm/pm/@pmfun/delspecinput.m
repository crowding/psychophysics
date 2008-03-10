%DELSPECINPUT Deletes a specific input definition from a pmfun
%   F = DELSPECINPUT(F,NAME) Deletes the specific input with the name
%   NAME from the pmfun definition and updates all other fields of the
%   pmfun in consequence. If pmblocks have been defined in F.blocks these
%   will also be updated and unused fields removed.
%
%   F = DELSPECINPUT(F,IND) Same as above except that the input is not
%   referenced by name but by index (into the datain/argin fields).
%
%   Example:
%      f = pmfun;
%      f = addspecinput(f,'img1','GETBLOC'); 
%      f = addspecinput(f,'img2','GETBLOC') 
%      f = delspecinput(f,'img1') % remove 1st reference
%                                 % The 2nd is then shifted to 1st.
%
%   See also: ADDCOMINPUT, DELCOMINPUT, ADDSPECINPUT, ADDOUTPUT, DELOUTPUT.

function f = delspecinput(f,var)
 
if isa(var,'double')
  dataind = var;
  if dataind > length(f.argin)
    error('The specific input does not contain that many entries (argin).')
  end
elseif ischar(var)
  dataind = find(strcmp(var, f.pmrpcfun.argin));
  if isempty(dataind)
    error('no variable exists with that name in function definition (argin).')
  end
else
  error('second argument must be either a double or a string');
end

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

destlist = {};
dstindlist = [];
for dst=f.dataout
  [t, r] = strtok(dst{:},'(');
  destlist{end+1} = t; 
  dstindlist(end+1) = str2num(r);
end


source = sourcelist{dataind}; 
blk_index = indexlist(dataind);
sourcelist(dataind) = []; % remove it!
indexlist(dataind) = [];
f.pmrpcfun.argin(dataind) = [];

% if something is deleted and its index is no longer used: 
% GETBLOC -> decr. index of higher GETBLOC,SRC,INPUT,LOADFILE
% SRC -> decr index of higher SRC, GETBLOC.
% LOADFILE or SRCFILE -> decr. index of higher LOADFILE, SRCFILE
% USERDATA -> decr. index of higher USERDATA
% MARGIN -> decr. index of higher MARGIN

dstdatainds = [];
switch source
 case 'SRC'
  datainds= find(strcmp('SRC',sourcelist) | strcmp('GETBLOC',sourcelist));
  blockfield = 'src';
 case 'GETBLOC'
  datainds= find(strcmp('GETBLOC',sourcelist));
  blockfield = 'src';
 case {'LOADFILE' 'SRCFILE'}
  datainds= find(strcmp('SRCFILE',sourcelist) | strcmp('LOADFILE',sourcelist)); 
  blockfield = 'srcfile';
 case 'DST'
  datainds = find(strcmp(source,sourcelist));
  dstdatainds =  find(strcmp('SETBLOC',destlist)); 
  blockfield = lower(source);
 case 'DSTFILE' 
  datainds = find(strcmp(source,sourcelist));
  dstdatainds =  find(strcmp('SAVEFILE',destlist)); 
  blockfield = lower(source);
 case {'MARGIN' 'TIMEOUT' 'USERDATA'}
  datainds = find(strcmp(source,sourcelist));
  blockfield = lower(source);
end
inds = [indexlist(datainds) dstindlist(dstdatainds)];
inds = unique(inds);

if strcmp(source,'GETBLOC')
  % GETBLOC to be deleted
  % => We need to update common arguments too.
  if ~ismember(blk_index,inds) % not used by other GETBLOC
    for common_ind =1:length(f.comdata)
      [data,ind] = strtok(f.comdata{common_ind},'(');
      if any(strcmp(data,{'INPUT','LOAD'}))
	ind = int2str(str2num(ind)-1);
	f.comdata{common_ind} = [data '(' ind ')'];
      end
    end
  end
  src_inds = find(strcmp('SRC',sourcelist));
  if ismember(blk_index,indexlist(src_inds)) % index used by SRC
    % this SRC needs to be shifted to a new index higher than all
    % GETBLOCs indices. All SRC higher than the highest GETBLOC index
    % must be increased by one to make space for this index.
    higher=find(indexlist(src_inds)==blk_index) % SRC to put after GETBLOC
    indexlist(src_inds(higher)) = repmat(max([1 inds]),size(higher))
    if ~isempty(f.blocks)
      try, src_attr = getattr(f.blocks,'src',blk_index);
	f.blocks = insertattr(f.blocks,'src',max([1 inds]),src_attr);
      catch
      end
    end
  else
    datainds = [datainds src_inds];
  end
end

if ~ismember(blk_index,inds) % this index is no longer used.
  if blk_index ~= 0 % indexed!
    higher = find(indexlist(datainds)>blk_index);
    indexlist(datainds(higher)) = indexlist(datainds(higher))-1;
    higher = find(dstindlist(dstdatainds)>blk_index);
    dstindlist(dstdatainds(higher)) = dstindlist(dstdatainds(higher))-1;
    if ~isempty(f.blocks)
      f.blocks = delattr(f.blocks,blockfield,blk_index);
    end
  end
end

f.datain = cell(size(sourcelist));
for n=1:length(sourcelist)
  if indexlist(n) == 0
    f.datain{n} = sourcelist{n};
  else
    f.datain{n} = [sourcelist{n} '(' int2str(indexlist(n)) ')'];
  end
end
for n=1:length(destlist)
  f.dataout{n} = [destlist{n} '(' int2str(dstindlist(n)) ')'];
end




