
% Parallel Matlab 
% make sure that matlab is always exited in a correct way.

if isunix
  
  % if it's not a spawned instance & has started a PMS session.
  if isempty(getenv('PVMEPID')) & ~isempty(getenv('PM_IS'));
    pmclose;
  else    % it is a spawned instance
    pvme_link
    if pvm_exit < 0  
      pvm_perror('')
      error('pvm_exit.m failed.')
    end
    pvme_unlink
  end
end

