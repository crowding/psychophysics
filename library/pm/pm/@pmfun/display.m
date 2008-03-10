function display(in)
  
  fprintf('\nPMFUN object  ')
  if length(in) == 1
    fprintf('\n')
    disp(struct(in.pmrpcfun))
    disp(struct(in));
  else
    for n=1:length(size(in))-1
      fprintf('%d x ',size(in,n));
    end
    fprintf('%d\n\n',size(in,n+1));
  end


