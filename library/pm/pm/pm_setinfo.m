function [] = pm_setinfo(mode,info)
%PM_SETINFO - auxiliary function of PM, for internal use only

% for setting the information parameters for a PMI.

  % constants
  PvmDataDefault      = 0;
  PvmMboxDefault      = 0;
  
  in.info = info;
  in.mode = mode;

  % update parameters
  info_table = ['PMINFO' int2str(pvm_mytid)];
  bufid = pvm_initsend(PvmDataDefault);
  v = version;
  if v(1) == '4'
    pvme_pkmat(in,'');
  else
    pvme_pkarray(in,'');
  end
  pvm_putinfo(info_table,bufid,PvmMboxDefault);
  pvm_freebuf(bufid);