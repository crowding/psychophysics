function tid = pmparent
%PMPARENT Return the id of the PMI that has spawned the calling PMI.
%   TID = PMPARENT 
%   If the calling PMI is not spawned from PMS, TID = []
%
%   See also PMID, PMALL, PMOTHERS, PMMEMBVM.
  
  tid = pvm_parent;
  if tid < 0
    tid = [];
  end


