%VMGET Returns the attribute(s) of a VM object.
%   VMGET(VMID) Returns the complete attribute structure of the VM object
%   indicated by VMID.
% 
%   [VALUE1, VALUE2, ... ] = VMGET(VMID, ATTRIBUTE1, ATTRIBUTE2, ...)
%   Returns the specified attributes of a VM object specified by VMID.
%   Valid attributes are: 'wd', 'prio', 'try', 'catch', 'runmode'
%
%   See also VM, VMDEL, VMIDS, PMSPAWN.

function varargout = vmget(id,varargin)

if nargin >= 2
  for n=1:nargin-1
    if ischar(varargin{n})  
      if ~ismember(varargin{n},{'display' 'wd' 'nice' 'tryex' 'catchex' 'runmode'})
	error('vmget: Invalid argument');
      end
    else
      error('vmget: Invalid argument');
    end
  end
end
  
bufid = pvm_recvinfo('PMVM',id,0);
if bufid < 0 & bufid ~= -32
  error(['vmget: pvm_recvinfo() failed. PVM error ' sprintf('%d',bufid)])
elseif bufid == -32 % not found!
  error('VM not found');
else
  v = version;
  if v(1) == '4'
    cnf = pvme_upkmat;
  else
    cnf = pvme_upkarray;
  end
  pvm_freebuf(bufid);
end

if nargin == 1
  varargout{1} = cnf;
  return
end

varargout = cell(1,nargin-1);
nargout = nargin-1;
for n = 1:nargin-1,
  varargout{n} = getfield(cnf,varargin{n});
end

  

