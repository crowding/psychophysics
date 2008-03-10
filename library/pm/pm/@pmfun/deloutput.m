%DELOUTPUT Deletes an output definition from a pmfun
%   F = DELOUTPUT(F,NAME) Deletes the output with the name NAME from the
%   pmfun definition and updates all other fields of the pmfun in
%   consequence. If pmblocks have been defined in F.blocks these will
%   also be updated and unused fields removed. 
%
%   F = DELOUTPUT(F,IND) Same as above except that the output is not
%   referenced by name but by index (into the dataout/argout fields).
%
%   Example:
%      f = pmfun;
%      f = addoutput(f,'img1','SETBLOC'); 
%      f = addoutput(f,'img2','SETBLOC') 
%      f = deloutput(f,'img1') % remove 1st reference
%                                 % The 2nd is then shifted to 1st.
%
%   See also: DELCOMINPUT, DELPECINPUT, ADDOUTPUT.

function f = deloutput(f,var)

if isa(var,'double')
  dataind = var;
  if dataind > length(f.argout)
    error('The specific input does not contain that many entries (argout).')
  end
elseif ischar(var)
  dataind = find(strcmp(var, f.pmrpcfun.argout));
  if isempty(dataind)
    error('no variable exists with that name in function definition (argout).')
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

dest = destlist{dataind}; 
blk_index = dstindlist(dataind);
destlist(dataind) = []; % remove it!
dstindlist(dataind) = [];
f.pmrpcfun.argout(dataind) = [];

% if something is deleted and its index is no longer used: 
% SETBLOC -> decr. index of higher SETBLOC,DST
% SAVEFILE -> decr index of higher SAVEFILE,DSTFILE

switch dest
 case 'SETBLOC'
  datainds = []; %find(strcmp('DST',sourcelist));
  dstdatainds = find(strcmp('SETBLOC',destlist)); 
  blockfield = 'dst';
 case 'SAVEFILE' 
  datainds = find(strcmp('DSTFILE',sourcelist));
  dstdatainds =  find(strcmp('SAVEFILE',destlist)); 
  blockfield = 'dstfile';
end
inds = [indexlist(datainds) dstindlist(dstdatainds)];
inds = unique(inds);

if strcmp(dest,'SETBLOC')
  % SETBLOC to be deleted
  dst_inds = find(strcmp('DST',sourcelist))
  if ismember(blk_index,indexlist(dst_inds)) % index used by DST
    higher=find(indexlist(dst_inds)==blk_index) % DST to put after SETBLOC
    indexlist(dst_inds(higher)) = repmat(max([1 inds]),size(higher))
    if ~isempty(f.blocks)
      try, dst_attr = getattr(f.blocks,'dst',blk_index);
	f.blocks = insertattr(f.blocks,'dst',max([1 inds]),dst_attr);
      catch
      end
    end
  else
    datainds = [datainds dst_inds];
  end
end


if ~ismember(blk_index,inds) % this index is no longer used.
  if blk_index ~= 0 % but indeed indexed!
    higher = find(indexlist(datainds)>blk_index);
    indexlist(datainds(higher)) = indexlist(datainds(higher))-1;
    higher = find(dstindlist(dstdatainds)>blk_index);
    dstindlist(dstdatainds(higher)) = dstindlist(dstdatainds(higher))-1;
    if ~isempty(f.blocks)
      f.blocks = delattr(f.blocks,blockfield,blk_index);
    end
  end
end

for n=1:length(sourcelist)
   if indexlist(n) == 0
    f.datain{n} = sourcelist{n};
  else
    f.datain{n} = [sourcelist{n} '(' int2str(indexlist(n)) ')'];
  end
end
f.dataout = cell(size(destlist));
for n=1:length(destlist)
  f.dataout{n} = [destlist{n} '(' int2str(dstindlist(n)) ')'];
end
