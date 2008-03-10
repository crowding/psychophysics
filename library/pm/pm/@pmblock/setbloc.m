function [] = setbloc(b,outp,data_name,varargin)
%SETBLOC Assign data to a partial matrix as specified by a PMBLOCK.
%   SETBLOC(PMBLOCK,OUTPUT_NAME,DATA_NAME,DST_INDEX) assigns data
%   from the variable by the name given by DATA_NAME to a part of the
%   variable specified by OUTPUT_NAME (string). Both these variables must
%   be in the caller's workspace. Which part of the output data variable
%   that will be assigned new values is specified by the PMBLOCK
%   attribute DST at the position specified by DST_INDEX. The DST
%   attribute of the PMLOCK consists of a cell array of entries that each
%   can be passed to an evaluation of substruct to create a structure
%   array usable by the subsref. Example: 
%   substr=eval('substruct(' pmblock.dst{1} ')') 
%   The indices for DST attributes can be created by CREATEINDS.
%
%   Example:
%      a=magic(8)
%      b = pmblock('dst',createinds(a,[4 4])); % blocks of 4x4
%      data = ones(4,4);
%      setbloc(b(2),'a','data',1) % change contents of second block
%      a
%
%   See also GETBLOC, PMBLOCK, CREATINDS.
  
  if nargin == 3 
    if iscell(b.dst)
      error(['incorrect use of PMBLOCK/SETBLOC. Input_index must be' ...
	     ' specified']);
    else
      ind = 1;
    end
  elseif varargin{1}~=1 & ~iscell(b.dst) 
    error(['incorrect use of PMBLOCK/SETBLOC. Input index to non inexistant' ...
	   ' field.']);
  else
    ind = varargin{1};
  end
  chind = sprintf('%d',ind);
  
  if iscell(b.dst)
    bl = b.dst{ind};
  else
    bl = b.dst;
  end

  evalin('caller',[outp '=subsasgn(' outp ', substruct(' bl '),' data_name ');'] );


  
 
  