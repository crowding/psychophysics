function [mode,info] = pmgetinfo(tid)
%PMGETINFO Return mode and information of a PMI.
%   [MODE, INFO]=PMGETINFO
%     MODE = 0 if in interactive mode
%     MODE = 1 if in extern mode
%     INFO = '' if PMI available
%     INFO = evalstring if PMI is executing something using PMEVAL/PMRPC.

% constants
  PvmMboxDefault      = 0;
  
  % load Task info and mode data
  info_table = ['PMINFO' sprintf('%d',tid)];
  bufid = pvm_recvinfo(info_table,0,PvmMboxDefault);
  if bufid < 0  
    warning(['pmgetmode: pvm_recvinfo() failed. Error ' int2str(bufid)])
    info = [];
  elseif bufid > 0
    v = version;
    if v(1) == '4'
      info = pvme_upkmat;
    else
      info = pvme_upkarray;
    end
    pvm_freebuf(bufid);
  else % not found.
    info = [];
  end
  
  if isempty(info)
    mode = [];
    return
  end
  
  mode = info.mode;
  info = info.info;
  
  
  
  