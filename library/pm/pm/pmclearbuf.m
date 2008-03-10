function info = pmclearbuf()
%PMCLEARBUF Clears the local PM message receive buffer.
  
% Constants
DpMsgTag = 9000;

bufid = pvm_probe(-1, DpMsgTag); 
while bufid>0,
  info = pvm_freebuf(bufid);
  bufid = pvm_probe(-1,DpMsgTag);
end
