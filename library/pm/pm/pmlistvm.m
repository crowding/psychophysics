function info = pmlistvm(varargin)
%PMLISTVM List all VM:s or the instances of a specific VM.
%   INFO = PMLISTVM Returns ids of all Virtual Machines.
%
%   INFO = PMLISTVM(PMID) Returns ids of all Virtual Machines of which
%   the PMI(s) specified by PMID is/are members. PMID can be a scalar or
%   a vector of PMIDs.
%
%   INFO contains a negative PVM error code if not succesful.
%  
%   See also PMEXPANDVM, PMMEMBVM, PMNEWVM.

% PVM constants
PvmMboxDefault = 0;
PvmNotFound = -32;

if nargin == 0
  info = vmids;
  return;
elseif nargin == 1
  names = ['PMVM' int2str(varargin{1})];
else
  error('Bad number of arguments.');
end

bufid = pvm_recvinfo(deblank(names),0,PvmMboxDefault);
if bufid < 0  &  bufid ~= PvmNotFound
  error('pmjoinvm: pvm_recvinfo() failed.')
end
if bufid > 0
  v = version;
  if v(1) == '4'
    info = pvme_upkmat;
  else
    info = pvme_upkarray;
  end
  pvm_freebuf(bufid);
else
  info = [];
end



