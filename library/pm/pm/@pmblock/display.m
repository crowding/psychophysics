% display method for PMBLOCK object 

% changed since v 1.00
% v1.01 31 March 2001
%  struct for all fields except 'v' are shown for single block display
%  information about how many entries for each attribute are show for multiple block display

function display(in)
  
  fprintf('\nPMBLOCK object version %s\n',version(in))
  if length(in) == 1
    fprintf('\n')
     d.src = in.src;
     d.dst = in.dst;
     d.srcfile = in.srcfile;
     d.dstfile = in.dstfile;
     d.userdata = in.userdata;
     d.timeout = in.timeout;
     disp(d);
  else
    for n=1:length(size(in))-1
      fprintf('%d x ',size(in,n));
    end
    fprintf('%d\n\n',size(in,n+1));
    fprintf('For each block there is:\n');
    flds = fieldnames(in(1));
    for k=1:length(flds)-2, 
      n = length(getfield(in(1),flds{k}));
      if n <= 1 
        fprintf('%4d entry of %s\n',n,flds{k});
      elseif n > 1 
        fprintf('%4d entries of %s\n',n,flds{k});
      end
    end
  end

