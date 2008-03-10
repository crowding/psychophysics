function data = getbloc(b,inp_name,varargin)
%GETBLOC Retrieve a partial matrix from data as specified by the PMBLOCK.
%   DATA = GETBLOC(PMBLOCK,INPUTNAME,SRC_INDEX) Returns the partial data
%   from the variable in the caller's workspace by the name provided by
%   INPUTNAME (string). The indices to use are specified by the attribute
%   SRC in the PMBLOCK object. SRC_INDEX determines which of the SRC
%   entries to use. The SRC attribute of the PMLOCK consists of a cell
%   array of entries that each can be passed to an evaluation of substruct
%   to create a structure array usable by the subsref. Example:
%   substr=eval('substruct(' pmblock.src{1} ')') 
%   The indices for SRC attributes can be created by CREATEINDS.
%  
%   Example:
%     a=magic(8)
%     b = pmblock('src',createinds(a,[4 4])); % blocks of 4x4
%     getbloc(b(2),'a',1) %look at second block
%
%   See also SETBLOC, PMBLOCK, CREATEINDS.

  if ~iscell(b.src) & (nargin<3 | (nargin==3 & varargin{1}==1))
    data = evalin('caller', ['subsref(' inp_name ', substruct(' b.src '))']);
  elseif nargin == 3 & iscell(b.src)
    data = evalin('caller', ['subsref(' inp_name ', substruct(' b.src{varargin{1}} '))']);
  else 
    error('Bad input arguments for @PMBLOCK/GETBLOC');
  end







