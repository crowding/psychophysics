function info = pmcancel(mi)
%PMCANCEL Send interrupt signal to PMI(s)
%   INFO=PMCANCEL(PMIDS) sends an interrupt signal (ctrl-c) to the PMI(s)
%   designated by PMIDS. INFO contains PVM error codes for each signal
%   sent. Values less than zero indicate an error.

  info = [];
  for i=1:length(mi) 
    info = [info pvm_sendsig(mi(i),2)];
  end


