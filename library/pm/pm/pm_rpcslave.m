function [] = pm_rpcslave(master);
%PM_RPCSLAVE - auxiliary function for PMRPC, for internal use only
  
% receive data from master

%  eval(['in = pmrecv(' sprintf('%d',master) ', ''RPC_IN'');']);
  in = pmrecv(master, 'RPC_IN');
  
  % 'in' is a struct with following contents:
  % .func = string to be evaluated
  % .in = cell array of input names (1st column) and data (2nd column)
  % .out = cell array of names of variables to be sent back
  % .debug = boolean describing if debug output will be done or not
  
%  evalin('base','lasterr('''')')
%  lasterr('')
  
  if in.debug
    fprintf('Received variables from %d:', master)
  end

  for i=1:size(in.in,2),
    assignin('caller', in.in{1,i}, in.in{2,i});
    if in.debug
      fprintf(' %s', in.in{1,i})
    end
  end

  % execute function 
  if in.debug
    fprintf('\n>>%d>> %s\n', master, in.func)
  end
  evalin('caller', in.func);

  nout = length(in.out);
  
  % pack the data into a cell before sending it back.
  for n=1:nout,
    evalin('caller',['RPC_OUT{' sprintf('%d',n) '}=' in.out{n} ';']);
  end
  
  if nout >= 1
    % send it back:
    evalin('caller',['pmsend(' sprintf('%d',master) ', RPC_OUT, ''RPC_OUT'');' ...
		     'clear RPC_OUT']);
    if in.debug
      fprintf('Sent back following variables :');
      for i=1:nout,
	fprintf(' %s', in.out{i});
      end
      fprintf('\n%d>',pmid);
    end
  elseif in.debug
    fprintf('No output from remote procedure call.');
  end



  
  
  
  
  
  
